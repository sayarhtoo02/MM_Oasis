import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';

import 'package:munajat_e_maqbool_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_orders_screen.dart';

class ShopNotificationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ShopService _shopService = ShopService();
  final NotificationService _notificationService;
  final GlobalKey<NavigatorState> navigatorKey;

  ShopNotificationService(this._notificationService, this.navigatorKey) {
    _listenToAuth();
  }

  RealtimeChannel? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _reminderTimer;
  List<String> _myShopIds = [];
  Map<String, String> _myShopNames = {};

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void _listenToAuth() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // User logged in
        initialize();
      } else {
        // User logged out
        disposeResources();
      }
    });
  }

  // Initialize service
  Future<void> initialize() async {
    try {
      debugPrint('ShopNotificationService: Initializing...');
      // 1. Get my shop IDs to filter notifications
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final myShops = await _shopService.getMyShops();
      _myShopIds = myShops.map((s) => s['id'] as String).toList();
      _myShopNames = {
        for (var s in myShops) s['id'] as String: s['name'] as String,
      };
      debugPrint('ShopNotificationService: My Shop IDs: $_myShopIds');

      if (_myShopIds.isEmpty) {
        debugPrint('ShopNotificationService: No shops found for this user.');
        return;
      }

      // 2. Subscribe to orders table
      _subscribeToOrders();

      // 3. Request battery optimization ignore
      await _requestBatteryOptimization();

      // 4. Start Reminder Timer
      _startReminderTimer();
    } catch (e) {
      debugPrint('Notification Service Init Error: $e');
    }
  }

  void _subscribeToOrders() {
    // Avoid double subscription
    if (_subscription != null) return;

    debugPrint('ShopNotificationService: Subscribing to orders table...');
    _subscription = _supabase
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'munajat_app',
          table: 'orders',
          callback: (payload) {
            _handleNewOrder(payload.newRecord);
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('ShopNotificationService: Subscribed!');
          }
        });
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    final orderShopId = order['shop_id'];

    // Check if this order looks like it belongs to one of my shops
    if (_myShopIds.contains(orderShopId)) {
      debugPrint('ShopNotificationService: New Order match! Notifying.');
      // It's for me!
      unreadCount.value++;
      notifyListeners();

      _playNotificationSound();
      _showLocalNotification(order);

      // Show Dialog via Navigator Key
      final context = navigatorKey.currentContext;
      if (context != null) {
        _showNotificationDialog(context, order);
      }
    }
  }

  void _startReminderTimer() {
    _reminderTimer?.cancel();
    // Check every 5 minutes
    _reminderTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkPendingOrders();
    });
  }

  Future<void> _checkPendingOrders() async {
    try {
      if (_myShopIds.isEmpty) return;

      final pendingOrders = await _supabase
          .schema('munajat_app')
          .from('orders')
          .select()
          .filter('shop_id', 'in', _myShopIds)
          .eq('status', 'pending_payment');

      if (pendingOrders.isNotEmpty) {
        final count = pendingOrders.length;
        unreadCount.value = count;
        notifyListeners();

        // Only notify if there are pending orders
        _notificationService.showOrderNotification(
          title: 'Pending Orders Reminder',
          body: 'You have $count orders waiting for confirmation!',
        );
      } else {
        unreadCount.value = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Reminder Check Error: $e');
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint(
        'ShopNotificationService: Error requesting battery optimization: $e',
      );
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> order) async {
    final customerName = order['customer_name'] ?? 'Customer';
    final total = order['total_amount'];
    await _notificationService.showOrderNotification(
      title: 'New Order Incoming!',
      body: 'Order from $customerName (K $total)',
    );
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/order_is_coming.wav'));
    } catch (e) {
      debugPrint('Audio Play Error: $e');
    }
  }

  void _showNotificationDialog(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    if (!context.mounted) return;

    final customerName = order['customer_name'] ?? 'A customer';
    final total = order['total_amount'];
    final shopId = order['shop_id'] as String;
    final shopName = _myShopNames[shopId] ?? 'My Shop';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.notifications_active, color: Colors.amber),
            SizedBox(width: 8),
            Text('New Order Incoming!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New order from $customerName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total Amount: K $total'),
            const SizedBox(height: 16),
            const Text('Please check the Orders tab to manage this order.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Shop Orders Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ShopOrdersScreen(shopId: shopId, shopName: shopName),
                ),
              );
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
  }

  void disposeResources() {
    _subscription?.unsubscribe();
    _subscription = null;
    _reminderTimer?.cancel();
    unreadCount.value = 0;
  }

  @override
  void dispose() {
    disposeResources();
    _authSubscription?.cancel();
    unreadCount.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
