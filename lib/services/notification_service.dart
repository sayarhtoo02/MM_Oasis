import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  NotificationService(this.notificationsPlugin) {
    tz.initializeTimeZones();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? granted = await androidImplementation
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      // Cancel any existing daily reminder
      await notificationsPlugin.cancel(0);

      // Calculate next occurrence
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Convert to TZDateTime
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await notificationsPlugin.zonedSchedule(
        0, // Always use ID 0 for daily reminder
        'Daily Dua Reminder',
        'Time for your daily Munajat-e-Maqbool recitation! 🤲',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminders',
            channelDescription: 'Daily dua reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelDailyReminder() async {
    await notificationsPlugin.cancel(0);
  }

  Future<void> showTestNotification() async {
    await notificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test notification to verify the system is working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Test notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showOrderNotification({
    required String title,
    required String body,
  }) async {
    await notificationsPlugin.show(
      // Use a unique ID based on time or random to allow stacking, or fixed ID to replace
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shop_orders', // New Channel ID
          'Shop Orders', // Channel Name
          channelDescription: 'Notifications for new shop orders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          // sound: RawResourceAndroidNotificationSound('order_is_coming'), // If we want custom sound from res/raw
          // For now, let's stick to default high priority sound or the one we played via audioplayers via the service.
          // Note: Custom sounds in notifications need the file in android/app/src/main/res/raw.
          // Since the user has it in assets/audio, it won't play automatically by notification unless moved.
          // BUT, we are playing audio via AudioPlayer in foreground.
          // For background, we rely on the OS sound or we need to move the file.
          // Let's assume default sound is okay or rely on the AudioPlayer if app is alive.
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }
}
