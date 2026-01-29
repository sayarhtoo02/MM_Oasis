import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/admin_service.dart';
import 'package:munajat_e_maqbool_app/screens/admin/shop_approval_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/user_management_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/admin_logs_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/admin_login_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/plan_management_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/ads_management_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/analytics_dashboard_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/payment_methods_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/subscription_requests_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/masjid_approval_screen.dart';
import 'package:munajat_e_maqbool_app/screens/admin/app_version_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
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
          title: 'Admin Dashboard',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: _loadStats,
            ),
            IconButton(
              icon: Icon(Icons.logout, color: textColor),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              'Pending',
                              '${_stats['pendingShops'] ?? 0}',
                              Icons.hourglass_empty,
                              Colors.orange,
                              isDark,
                              textColor,
                              onTap: () => _navigateToApprovals(),
                            ),
                            _buildStatCard(
                              'Approved',
                              '${_stats['approvedShops'] ?? 0}',
                              Icons.check_circle,
                              Colors.green,
                              isDark,
                              textColor,
                            ),
                            _buildStatCard(
                              'Users',
                              '${_stats['totalUsers'] ?? 0}',
                              Icons.people,
                              Colors.blue,
                              isDark,
                              textColor,
                              onTap: () => _navigateToUsers(),
                            ),
                            _buildStatCard(
                              'Reviews',
                              '${_stats['totalReviews'] ?? 0}',
                              Icons.star,
                              Colors.amber,
                              isDark,
                              textColor,
                            ),
                            _buildStatCard(
                              'Masjids',
                              '${_stats['totalMasjids'] ?? 0}',
                              'assets/icons/icon_masjid.png',
                              Colors.teal,
                              isDark,
                              textColor,
                              onTap: _navigateToMasjidApprovals,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildActionTile(
                          icon: Icons.pending_actions,
                          title: 'Shop Approvals',
                          subtitle: '${_stats['pendingShops'] ?? 0} pending',
                          onTap: _navigateToApprovals,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.orange,
                        ),

                        _buildActionTile(
                          icon: 'assets/icons/icon_masjid.png',
                          title: 'Masjid Approvals',
                          subtitle: '${_stats['pendingMasjids'] ?? 0} pending',
                          onTap: _navigateToMasjidApprovals,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.teal,
                        ),

                        _buildActionTile(
                          icon: Icons.people_outline,
                          title: 'User Management',
                          subtitle: 'Manage users and roles',
                          onTap: _navigateToUsers,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.blue,
                        ),

                        _buildActionTile(
                          icon: Icons.history,
                          title: 'Admin Logs',
                          subtitle: 'View action history',
                          onTap: _navigateToLogs,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.purple,
                        ),

                        _buildActionTile(
                          icon: Icons.subscriptions,
                          title: 'Subscription Plans',
                          subtitle: 'Manage plans and features',
                          onTap: _navigateToPlans,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.teal,
                        ),

                        _buildActionTile(
                          icon: Icons.campaign,
                          title: 'Ads Management',
                          subtitle: 'Create and manage banners',
                          onTap: _navigateToAds,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.amber,
                        ),

                        _buildActionTile(
                          icon: Icons.analytics,
                          title: 'Analytics',
                          subtitle: 'View growth and statistics',
                          onTap: _navigateToAnalytics,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.indigo,
                        ),

                        _buildActionTile(
                          icon: Icons.payment,
                          title: 'Payment Methods',
                          subtitle: 'KBZ, Wave, AYA Pay settings',
                          onTap: _navigateToPaymentMethods,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.cyan,
                        ),

                        _buildActionTile(
                          icon: Icons.receipt_long,
                          title: 'Subscription Requests',
                          subtitle: 'Review payment screenshots',
                          onTap: _navigateToSubscriptionRequests,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.deepOrange,
                        ),

                        _buildActionTile(
                          icon: Icons.system_update,
                          title: 'App Updates',
                          subtitle: 'Manage versions and APKs',
                          onTap: _navigateToAppVersions,
                          isDark: isDark,
                          textColor: textColor,
                          accentColor: Colors.blueGrey,
                        ),

                        const SizedBox(height: 24),

                        // Summary Stats
                        Text(
                          'Summary',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        GlassCard(
                          isDark: isDark,
                          borderRadius: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  'Total Shops',
                                  '${_stats['totalShops'] ?? 0}',
                                  textColor,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Rejected',
                                  '${_stats['rejectedShops'] ?? 0}',
                                  textColor,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Suspended',
                                  '${_stats['suspendedShops'] ?? 0}',
                                  textColor,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Total Masjids',
                                  '${_stats['totalMasjids'] ?? 0}',
                                  textColor,
                                ),
                                _buildSummaryRow(
                                  'Approved Masjids',
                                  '${_stats['approvedMasjids'] ?? 0}',
                                  textColor,
                                ),
                                _buildSummaryRow(
                                  'Pending Masjids',
                                  '${_stats['pendingMasjids'] ?? 0}',
                                  textColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    dynamic icon,
    Color color,
    bool isDark,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon is IconData
                ? Icon(icon, color: color, size: 32)
                : Image.asset(icon as String, width: 32, height: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon is IconData
                    ? Icon(icon, color: accentColor)
                    : Image.asset(icon as String, width: 24, height: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
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

  Widget _buildSummaryRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShopApprovalScreen()),
    ).then((_) => _loadStats());
  }

  void _navigateToMasjidApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MasjidApprovalScreen()),
    ).then((_) => _loadStats());
  }

  void _navigateToUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminLogsScreen()),
    );
  }

  void _navigateToPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanManagementScreen()),
    );
  }

  void _navigateToAds() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdsManagementScreen()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
    );
  }

  void _navigateToPaymentMethods() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
    );
  }

  void _navigateToSubscriptionRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionRequestsScreen(),
      ),
    );
  }

  void _navigateToAppVersions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppVersionManagementScreen(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from admin panel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AdminAuth.logout();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
