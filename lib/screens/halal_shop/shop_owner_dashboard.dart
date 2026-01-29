import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_registration_screen.dart';
import 'package:munajat_e_maqbool_app/services/shop_notification_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_edit_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_notifications_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/subscription_screen.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';
import 'package:munajat_e_maqbool_app/services/order_service.dart';
import 'package:munajat_e_maqbool_app/services/ads_service.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_orders_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_menu_editor.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_detail_screen.dart';

class ShopOwnerDashboard extends StatefulWidget {
  const ShopOwnerDashboard({super.key});

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final AdsService _adsService = AdsService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  late final ShopNotificationService _notificationService;
  List<Map<String, dynamic>> _myShops = [];
  Map<String, dynamic>? _subscriptionPlan;
  Map<String, dynamic> _dashboardStats = {
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'views': 0,
  };
  bool _isLoading = true;
  int _selectedShopIndex = 0; // NEW: Track selected shop context

  @override
  void initState() {
    super.initState();
    _loadMyShops();
    _notificationService = Provider.of<ShopNotificationService>(
      context,
      listen: false,
    );
  }

  Future<void> _loadMyShops() async {
    setState(() => _isLoading = true);
    try {
      final shops = await _shopService.getMyShops();
      final plan = await _subscriptionService.getCurrentUserPlan();
      final stats = await _orderService.getOwnerDashboardStats();

      if (mounted) {
        setState(() {
          _myShops = shops;
          _subscriptionPlan = plan;
          _dashboardStats = stats;
          _isLoading = false;
          // Ensure index is valid if list shrinks/changes
          if (_selectedShopIndex >= _myShops.length) {
            _selectedShopIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  void _addNewShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShopRegistrationScreen()),
    ).then((_) => _loadMyShops());
  }

  // --- UI Helpers ---

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'suspended':
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (_authService.currentUser == null) {
          return _buildLoginRequiredState(context, isDark);
        }

        return Scaffold(
          backgroundColor: GlassTheme.background(isDark),
          body: Stack(
            children: [
              Container(color: GlassTheme.background(isDark)),
              AppBackgroundPattern(
                patternColor: isDark ? Colors.white : Colors.black,
                opacity: isDark ? 0.05 : 0.03,
              ),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Dashboard Header
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: GlassTheme.glassGradient(
                      isDark,
                    ).first.withValues(alpha: 0.95),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      title: _myShops.isEmpty
                          ? Text(
                              'Dashboard',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : PopupMenuButton<int>(
                              initialValue: _selectedShopIndex,
                              onSelected: (index) {
                                setState(() {
                                  _selectedShopIndex = index;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _myShops[_selectedShopIndex]['name'] ??
                                          'Shop',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                              itemBuilder: (context) {
                                return List.generate(_myShops.length, (index) {
                                  return PopupMenuItem(
                                    value: index,
                                    child: Text(
                                      _myShops[index]['name'] ?? 'Shop',
                                      style: TextStyle(
                                        color: index == _selectedShopIndex
                                            ? accentColor
                                            : null,
                                        fontWeight: index == _selectedShopIndex
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                      background: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20, top: 40),
                          child: Icon(
                            Icons.dashboard_rounded,
                            size: 100,
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      ValueListenableBuilder<int>(
                        valueListenable: _notificationService.unreadCount,
                        builder: (context, count, child) {
                          return IconButton(
                            icon: Badge(
                              isLabelVisible: count > 0,
                              label: Text('$count'),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: textColor,
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopNotificationsScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // 2. Main Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. Subscription Overview
                          _buildSubscriptionCard(
                            isDark,
                            textColor,
                            accentColor,
                          ),
                          const SizedBox(height: 24),

                          // B. Stats (Mock)
                          _buildStatsOverview(isDark, textColor, accentColor),
                          const SizedBox(height: 24),

                          // C. Quick Actions
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionsGrid(
                            isDark,
                            textColor,
                            accentColor,
                          ),
                          const SizedBox(height: 24),

                          // D. Shops List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Shops',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              if (_myShops.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _addNewShop,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add New'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: accentColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_isLoading)
                            Center(
                              child: CircularProgressIndicator(
                                color: accentColor,
                              ),
                            )
                          else if (_myShops.isEmpty)
                            _buildEmptyState(textColor, accentColor, isDark)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _myShops.length,
                              itemBuilder: (context, index) {
                                return _buildShopCard(
                                  _myShops[index],
                                  isDark,
                                  textColor,
                                  accentColor,
                                );
                              },
                            ),

                          const SizedBox(height: 80), // Padding for bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: _myShops.isEmpty
              ? FloatingActionButton.extended(
                  onPressed: _addNewShop,
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Create Shop'),
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                )
              : null,
        );
      },
    );
  }

  // --- Widget Builders ---

  Widget _buildLoginRequiredState(BuildContext context, bool isDark) {
    return GlassScaffold(
      title: 'Dashboard',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please login to manage your shops',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(bool isDark, Color textColor, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Orders',
            _dashboardStats['totalOrders'].toString(),
            Icons.receipt_long_rounded,
            Colors.blue,
            isDark,
            textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Views',
            _dashboardStats['views'] > 1000
                ? '${(_dashboardStats['views'] / 1000).toStringAsFixed(1)}k'
                : _dashboardStats['views'].toString(),
            Icons.visibility_rounded,
            Colors.purple,
            isDark,
            textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Revenue',
            '\$${_dashboardStats['totalRevenue'] > 1000 ? '${(_dashboardStats['totalRevenue'] / 1000).toStringAsFixed(1)}k' : _dashboardStats['totalRevenue'].toStringAsFixed(0)}',
            Icons.attach_money_rounded,
            Colors.green,
            isDark,
            textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      isDarkForce: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    // Functional items
    final actions = [
      {
        'icon': Icons.add_box_outlined,
        'label': 'Add Item',
        'color': Colors.blue,
        'onTap': () {
          if (_myShops.isEmpty) {
            _addNewShop();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopMenuEditor(
                  shopId: _myShops[_selectedShopIndex]['id'],
                  shopName: _myShops[_selectedShopIndex]['name'] ?? 'Shop',
                ),
              ),
            );
          }
        },
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Orders',
        'color': Colors.purple,
        'onTap': () {
          if (_myShops.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopOrdersScreen(
                  shopId: _myShops[_selectedShopIndex]['id'],
                  shopName: _myShops[_selectedShopIndex]['name'] ?? 'Shop',
                ),
              ),
            );
          }
        },
      },
      {
        'icon': Icons.campaign_outlined,
        'label': 'Promote',
        'color': Colors.orange,
        'onTap': () => _showPromotionDialog(
          context,
          isDark,
          textColor,
          accentColor,
          _myShops[_selectedShopIndex], // Pass selected shop
        ),
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'color': Colors.grey,
        'onTap': () {
          if (_myShops.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ShopEditScreen(shopId: _myShops[_selectedShopIndex]['id']),
              ),
            ).then((_) => _loadMyShops());
          }
        },
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  onTap: action['onTap'] as VoidCallback,
                  isDarkForce: isDark,
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionCard(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    // ... logic same as before, essentially simplified for the new layout
    final planName = _subscriptionPlan?['name'] as String? ?? 'Free';
    final isPro = _subscriptionPlan?['show_premium_badge'] == true;

    // Golden Gradient for Pro
    final proGradient = LinearGradient(
      colors: [
        const Color(0xFFFFD700).withValues(alpha: 0.3), // Gold
        const Color(0xFFB8860B).withValues(alpha: 0.4), // Dark Goldenrod
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GlassCard(
      isDarkForce:
          isDark, // Using the new parameter name if available or fallback
      borderRadius: 16,
      borderColor: isPro
          ? const Color(0xFFFFD700).withValues(alpha: 0.5)
          : null,
      gradientColors: isPro
          ? [proGradient.colors[0], proGradient.colors[1]]
          : null,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          ).then((_) => _loadMyShops());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPro ? const Color(0xFFFFD700) : accentColor)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPro ? Icons.verified : Icons.card_membership,
                  color: isPro ? const Color(0xFFFFD700) : accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          planName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (isPro) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color accentColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.storefront_rounded,
            size: 60,
            color: textColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  void _toggleShopStatus(Map<String, dynamic> shop, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await _shopService.toggleShopOpenStatus(shop['id'], newStatus);

      if (mounted) {
        setState(() {
          shop['is_open'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Shop is now OPEN' : 'Shop is now CLOSED',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling status: $e')));
      }
    }
  }

  void _showPromotionDialog(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color accentColor,
    Map<String, dynamic> shop, // New param
  ) {
    // validation for empty shops is handled by caller now or implicitly
    if (_myShops.isEmpty) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController =
        TextEditingController(); // Placeholder for image upload or URL

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.glassGradient(isDark).first,
        title: Text('Request Promotion', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Ad Title',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Ad Description',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Banner Image URL',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adsService.requestPromotion(
                  shopId: shop['id'],
                  adTitle: titleController.text,
                  adDescription: descController.text,
                  bannerUrl: urlController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion request sent!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(
    Map<String, dynamic> shop,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final status = shop['status'] as String? ?? 'pending';
    final isOpen = shop['is_open'] as bool? ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDarkForce: isDark,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopEditScreen(shopId: shop['id']),
            ),
          ).then((_) => _loadMyShops());
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Shop Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store_rounded, color: accentColor),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'] ?? 'Shop Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 14,
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Open/Close Toggle (Manual Override)
                  GestureDetector(
                    onTap: () => _toggleShopStatus(shop, isOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpen
                                ? Icons.check_circle_outline
                                : Icons.power_settings_new,
                            size: 12,
                            color: isOpen ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Footer
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: GlassTheme.glassBorder(isDark)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopDetailScreen(shopId: shop['id']),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      label: Text(
                        'Preview',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: GlassTheme.glassBorder(isDark),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopEditScreen(shopId: shop['id']),
                          ),
                        ).then((_) => _loadMyShops());
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: accentColor,
                      ),
                      label: Text(
                        'Edit Shop',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
