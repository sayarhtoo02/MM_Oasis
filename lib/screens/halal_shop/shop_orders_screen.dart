import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/order_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class ShopOrdersScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopOrdersScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;
  int _previousOrderCount = 0;

  final List<String> _tabs = [
    'All', // New "All" tab
    'Pending',
    'Payment',
    'Preparing',
    'Ready',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initializeNotifications();
    _subscribeToOrders();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // Request permissions
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _subscribeToOrders() {
    _ordersSubscription = _orderService
        .streamShopOrders(widget.shopId)
        .listen(
          (orders) {
            if (mounted) {
              // Check for new orders
              if (orders.length > _previousOrderCount && !_isLoading) {
                // Find the new order (simplified logic: just check if count increased)
                // In a perfect world we diff the lists, but for now this is "loud" enough
                final newPending = orders
                    .where((o) => o['status'] == 'pending_payment')
                    .length;
                final oldPending = _allOrders
                    .where((o) => o['status'] == 'pending_payment')
                    .length;

                if (newPending > oldPending) {
                  _showNewOrderNotification();
                }
              }

              setState(() {
                _allOrders = orders;
                _isLoading = false;
                _previousOrderCount = orders.length;
              });
            }
          },
          onError: (error) {
            debugPrint('Error streaming orders: $error');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        );
  }

  Future<void> _showNewOrderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'shop_orders_channel',
      'Shop Orders',
      channelDescription: 'Notifications for new shop orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true, // "Loud" behavior
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      'New Order Received! 🔔',
      'A new order has been placed at ${widget.shopName}',
      details,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ... (Notification methods remain unchanged)

  // Helper to count orders for badges
  int _getCountForTab(int index) {
    // We use the same filtering logic but without search text for counts
    // to show total available in that tab
    return _filterOrders(_getOrdersForTabIndex(index), '').length;
  }

  // Refactored to get raw list for tab index
  List<Map<String, dynamic>> _getOrdersForTabIndex(int tabIndex) {
    switch (tabIndex) {
      case 0: // All
        return _allOrders;
      case 1: // Pending
        return _allOrders
            .where(
              (o) =>
                  o['status'] == 'pending_payment' ||
                  o['status'] == 'payment_uploaded',
            )
            .toList();
      case 2: // Payment
        return _allOrders
            .where((o) => o['status'] == 'payment_confirmed')
            .toList();
      case 3: // Preparing
        return _allOrders.where((o) => o['status'] == 'preparing').toList();
      case 4: // Ready
        return _allOrders.where((o) => o['status'] == 'ready').toList();
      case 5: // Completed
        return _allOrders
            .where(
              (o) => o['status'] == 'completed' || o['status'] == 'cancelled',
            )
            .toList();
      default:
        return [];
    }
  }

  // Apply Search Filter
  List<Map<String, dynamic>> _filterOrders(
    List<Map<String, dynamic>> orders,
    String query,
  ) {
    if (query.isEmpty) return orders;
    return orders.where((order) {
      final id = order['id'].toString().toLowerCase();
      final name = (order['customer_name'] ?? '').toString().toLowerCase();
      final phone = (order['customer_phone'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return id.contains(q) || name.contains(q) || phone.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _getOrdersForTab(int tabIndex) {
    final rawOrders = _getOrdersForTabIndex(tabIndex);
    return _filterOrders(rawOrders, _searchText);
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      // Stream will auto-update UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to ${OrderService.getStatusText(newStatus)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Orders - ${widget.shopName}',
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                _ordersSubscription?.cancel();
                _subscribeToOrders();
              },
            ),
          ],
          body: Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Order ID...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // 2. Tab Bar with Badges
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: accentColor,
                unselectedLabelColor: textColor.withValues(alpha: 0.5),
                indicatorColor: accentColor,
                tabs: List.generate(_tabs.length, (index) {
                  final label = _tabs[index];
                  final count = _getCountForTab(index);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          _tabs.length,
                          (index) => _buildOrderList(
                            _getOrdersForTab(index),
                            isDark,
                            textColor,
                            accentColor,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders',
          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isDark, textColor, accentColor);
      },
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final status = order['status'] as String;
    final statusColor = Color(OrderService.getStatusColor(status));
    final createdAt = DateTime.parse(
      order['created_at'],
    ).toLocal(); // Ensure local time
    final total = order['total_amount'] as num?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDarkForce: isDark,
        borderRadius: 16,
        onTap: () => _showOrderDetails(order, isDark, textColor, accentColor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['customer_name'] ?? 'Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      OrderService.getStatusText(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 14,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order['customer_phone'] ?? 'No phone',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'K ${total?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // Action buttons based on status
              if (status == 'payment_uploaded') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewPaymentScreenshot(order),
                        icon: const Icon(Icons.image, size: 16),
                        label: const Text('View Payment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(order['id'], 'payment_confirmed'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (status == 'payment_confirmed') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order['id'], 'preparing'),
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('Start Preparing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
              if (status == 'preparing') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order['id'], 'ready'),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark Ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              if (status == 'ready') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order['id'], 'completed'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Complete Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _viewPaymentScreenshot(Map<String, dynamic> order) {
    final url = order['payment_screenshot_url'] as String?;
    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No payment screenshot')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Screenshot'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Image.network(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) async {
    final details = await _orderService.getOrderDetails(order['id']);
    if (details == null || !mounted) return;

    final items = details['items'] as List<Map<String, dynamic>>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['quantity']}x ${item['item_name']}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    Text(
                      'K ${((item['item_price'] as num) * (item['quantity'] as int)).toStringAsFixed(0)}',
                      style: TextStyle(color: accentColor),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                Text(
                  'K ${(details['total_amount'] as num).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            if (details['notes'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Notes: ${details['notes']}',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
