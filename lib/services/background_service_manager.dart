import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundServiceManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'shop_orders',
        initialNotificationTitle: 'Shop Monitoring Active',
        initialNotificationContent: 'Waiting for new orders...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> requestUnrestrictedBattery() async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Local Notifications for Lock Screen
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings(
    '@mipmap/launcher_icon',
  );
  const initSettings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(initSettings);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // 1. Initialize Supabase in Background Isolate
  try {
    await Supabase.initialize(
      url: 'https://lgmbvrtkulhwylmwhoou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWJ2cnRrdWxod3lsbXdob291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MDc5NTIsImV4cCI6MjA4MzI4Mzk1Mn0.MUl09e5NufjdyO0J0kP1u9BETBTQuNOMgvAXXuEsx_o',
    );
  } catch (e) {
    debugPrint('Background Isolate: Supabase already initialized or fail: $e');
  }

  final supabase = Supabase.instance.client;
  final audioPlayer = AudioPlayer();

  // 2. Fetch shops for the logged in user
  final user = supabase.auth.currentUser;
  if (user == null) {
    debugPrint('Background Isolate: No user sessions found. Sleeping.');
    return;
  }

  List<String> myShopIds = [];
  try {
    final response = await supabase
        .schema('munajat_app')
        .from('shops')
        .select('id')
        .eq('owner_id', user.id);
    myShopIds = (response as List).map((s) => s['id'] as String).toList();
  } catch (e) {
    debugPrint('Background Isolate: Error fetching shops: $e');
  }

  if (myShopIds.isEmpty) return;

  // Helper to show high-priority lock-screen notification
  Future<void> showLockScreenNotification(String title, String body) async {
    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shop_orders_high',
          'Order Alerts',
          channelDescription: 'Urgent order notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true, // Shows on lock screen
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  // 3. Subscribe to Realtime Orders
  supabase
      .channel('background:orders')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'munajat_app',
        table: 'orders',
        callback: (payload) async {
          final order = payload.newRecord;
          final shopId = order['shop_id'];

          if (myShopIds.contains(shopId)) {
            // New Order!
            // Update Foreground Service Notification
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: 'New Order Received!',
                content:
                    'Order from ${order['customer_name']} (K ${order['total_amount']})',
              );
            }

            // Show Lock-Screen Notification
            await showLockScreenNotification(
              '🔔 New Order Incoming!',
              'Order from ${order['customer_name']} (K ${order['total_amount']})',
            );

            // Play Sound
            try {
              await audioPlayer.play(AssetSource('audio/order_is_coming.wav'));
            } catch (e) {
              debugPrint('Background Audio Error: $e');
            }
          }
        },
      )
      .subscribe();

  // 4. Periodic Pending Order Reminder (every 1 minute for testing)
  Timer.periodic(const Duration(minutes: 3), (timer) async {
    try {
      // Check for orders that are not completed/delivered
      final pendingOrders = await supabase
          .schema('munajat_app')
          .from('orders')
          .select()
          .filter('shop_id', 'in', myShopIds)
          .inFilter('status', [
            'pending_payment',
            'pending',
            'confirmed',
            'preparing',
          ]);

      if (pendingOrders.isNotEmpty) {
        final count = pendingOrders.length;

        // Update Foreground Notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: '⚠️ $count Pending Orders',
            content: 'Orders awaiting confirmation!',
          );
        }

        // Show Lock-Screen Reminder
        await showLockScreenNotification(
          '⚠️ $count Orders Waiting!',
          'You have pending orders that need confirmation.',
        );

        // Play reminder sound
        try {
          await audioPlayer.play(AssetSource('audio/old_order_reminder.wav'));
        } catch (e) {
          debugPrint('Background Reminder Audio Error: $e');
        }
      } else {
        // Reset to default status
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Shop Monitoring Active',
            content: 'Waiting for new orders...',
          );
        }
      }
    } catch (e) {
      debugPrint('Background Reminder Check Error: $e');
    }
  });
}
