import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/admin_service.dart';

class ShopApprovalScreen extends StatefulWidget {
  const ShopApprovalScreen({super.key});

  @override
  State<ShopApprovalScreen> createState() => _ShopApprovalScreenState();
}

class _ShopApprovalScreenState extends State<ShopApprovalScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingShops = [];
  List<Map<String, dynamic>> _allShops = [];
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _adminService.getPendingShops(),
      _adminService.getAllShops(
        statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
      ),
    ]);

    if (mounted) {
      setState(() {
        _pendingShops = results[0];
        _allShops = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _approveShop(Map<String, dynamic> shop) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Shop?'),
        content: Text(
          'Approve "${shop['name']}"? It will become visible to all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.approveShop(shop['id']);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop approved!'),
            backgroundColor: Colors.green,
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

  Future<void> _rejectShop(Map<String, dynamic> shop) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${shop['name']}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await _adminService.rejectShop(shop['id'], reason: result);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shop rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _suspendShop(Map<String, dynamic> shop) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Suspend "${shop['name']}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await _adminService.suspendShop(shop['id'], reason: result);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shop suspended')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Shop Approvals',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: _loadData,
            ),
          ],
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: accentColor,
                unselectedLabelColor: textColor.withValues(alpha: 0.5),
                tabs: [
                  Tab(text: 'Pending (${_pendingShops.length})'),
                  const Tab(text: 'All Shops'),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildShopList(
                            _pendingShops,
                            isDark,
                            textColor,
                            accentColor,
                            isPending: true,
                          ),
                          _buildAllShopsTab(isDark, textColor, accentColor),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllShopsTab(bool isDark, Color textColor, Color accentColor) {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', '', isDark, textColor, accentColor),
                _buildFilterChip(
                  'Approved',
                  'approved',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildFilterChip(
                  'Pending',
                  'pending',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildFilterChip(
                  'Rejected',
                  'rejected',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildFilterChip(
                  'Suspended',
                  'suspended',
                  isDark,
                  textColor,
                  accentColor,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildShopList(
            _allShops,
            isDark,
            textColor,
            accentColor,
            isPending: false,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = selected ? value : '';
          });
          _loadData();
        },
        selectedColor: accentColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: isSelected ? accentColor : textColor),
      ),
    );
  }

  Widget _buildShopList(
    List<Map<String, dynamic>> shops,
    bool isDark,
    Color textColor,
    Color accentColor, {
    required bool isPending,
  }) {
    if (shops.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending shops' : 'No shops found',
          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return _buildShopCard(shop, isDark, textColor, accentColor, isPending);
      },
    );
  }

  Widget _buildShopCard(
    Map<String, dynamic> shop,
    bool isDark,
    Color textColor,
    Color accentColor,
    bool isPending,
  ) {
    final status = shop['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final owner = shop['owner'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.storefront, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by ${owner?['username'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              if (shop['description'] != null)
                Text(
                  shop['description'],
                  style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shop['address'] ?? 'No address',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending') ...[
                    TextButton.icon(
                      onPressed: () => _rejectShop(shop),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveShop(shop),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  if (status == 'approved')
                    TextButton.icon(
                      onPressed: () => _suspendShop(shop),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspend'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  if (status == 'suspended' || status == 'rejected')
                    ElevatedButton.icon(
                      onPressed: () => _approveShop(shop),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Reactivate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
