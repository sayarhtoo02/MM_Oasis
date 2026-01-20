import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_orders_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ShopNotificationsScreen extends StatefulWidget {
  const ShopNotificationsScreen({super.key});

  @override
  State<ShopNotificationsScreen> createState() =>
      _ShopNotificationsScreenState();
}

class _ShopNotificationsScreenState extends State<ShopNotificationsScreen> {
  final ShopService _shopService = ShopService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Get my shops
      final myShops = await _shopService.getMyShops();
      final shopIds = myShops.map((s) => s['id'] as String).toList();
      final shopNames = {
        for (var s in myShops) s['id'] as String: s['name'] as String,
      };

      if (shopIds.isEmpty) {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch orders for these shops (Limit 50 for notifications)
      final response = await _supabase
          .schema('munajat_app')
          .from('orders')
          .select()
          .filter('shop_id', 'in', shopIds)
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        response,
      );

      // 3. Process into notification models
      // We treat every order as a "notification" of sorts
      final processed = orders.map((order) {
        final shopId = order['shop_id'] as String;
        return {
          'id': order['id'],
          'type': 'order',
          'title': 'New Order',
          'body': 'Order from ${order['customer_name'] ?? 'Customer'}',
          'amount': order['total_amount'],
          'created_at': DateTime.parse(order['created_at']).toLocal(),
          'shop_id': shopId,
          'shop_name': shopNames[shopId] ?? 'Unknown Shop',
          'status': order['status'],
          'is_pending':
              order['status'] == 'pending_payment' ||
              order['status'] == 'pending',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
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
          title: 'Notifications',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationCard(
                        notif,
                        isDark,
                        textColor,
                        accentColor,
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notif,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isPending = notif['is_pending'] as bool;
    final createdAt = notif['created_at'] as DateTime;
    final timeAgo = timeago.format(createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        onTap: () {
          // Navigate to orders screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopOrdersScreen(
                shopId: notif['shop_id'],
                shopName: notif['shop_name'],
              ),
            ),
          ).then((_) => _loadNotifications()); // Refresh on return
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withValues(alpha: 0.1)
                      : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPending ? Icons.notifications_active : Icons.receipt_long,
                  color: isPending ? Colors.orange : accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif['shop_name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: K ${notif['amount']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Waiting for confirmation',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: textColor.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
