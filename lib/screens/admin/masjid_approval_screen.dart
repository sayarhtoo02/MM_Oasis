import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/admin_service.dart';

class MasjidApprovalScreen extends StatefulWidget {
  const MasjidApprovalScreen({super.key});

  @override
  State<MasjidApprovalScreen> createState() => _MasjidApprovalScreenState();
}

class _MasjidApprovalScreenState extends State<MasjidApprovalScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingMasjids = [];
  List<Map<String, dynamic>> _allMasjids = [];
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

    try {
      final results = await Future.wait([
        _adminService.getPendingMasjids(),
        _adminService.getAllMasjids(
          statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
        ),
      ]);

      if (mounted) {
        setState(() {
          _pendingMasjids = results[0];
          _allMasjids = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading masjids: $e')));
      }
    }
  }

  Future<void> _approveMasjid(Map<String, dynamic> masjid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Masjid?'),
        content: Text(
          'Approve "${masjid['name']}"? It will become visible to all users.',
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
      await _adminService.approveMasjid(masjid['id']);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masjid approved!'),
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

  Future<void> _rejectMasjid(Map<String, dynamic> masjid) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Masjid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${masjid['name']}"?'),
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
      await _adminService.rejectMasjid(masjid['id'], reason: result);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Masjid rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _suspendMasjid(Map<String, dynamic> masjid) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Masjid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Suspend "${masjid['name']}"?'),
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
      await _adminService.suspendMasjid(masjid['id'], reason: result);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Masjid suspended')));
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
          title: 'Masjid Approvals',
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
                indicatorColor: accentColor,
                tabs: [
                  Tab(text: 'Pending (${_pendingMasjids.length})'),
                  const Tab(text: 'All Masjids'),
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
                          _buildMasjidList(
                            _pendingMasjids,
                            isDark,
                            textColor,
                            accentColor,
                            isPending: true,
                          ),
                          _buildAllMasjidsTab(isDark, textColor, accentColor),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllMasjidsTab(bool isDark, Color textColor, Color accentColor) {
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
          child: _buildMasjidList(
            _allMasjids,
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

  Widget _buildMasjidList(
    List<Map<String, dynamic>> masjids,
    bool isDark,
    Color textColor,
    Color accentColor, {
    required bool isPending,
  }) {
    if (masjids.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending masjids' : 'No masjids found',
          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: masjids.length,
      itemBuilder: (context, index) {
        final masjid = masjids[index];
        return _buildMasjidCard(
          masjid,
          isDark,
          textColor,
          accentColor,
          isPending,
        );
      },
    );
  }

  Widget _buildMasjidCard(
    Map<String, dynamic> masjid,
    bool isDark,
    Color textColor,
    Color accentColor,
    bool isPending,
  ) {
    final status = masjid['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final manager = masjid['manager'] as Map<String, dynamic>?;

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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/icons/icon_masjid.png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          masjid['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by ${manager?['username'] ?? 'Unknown'}',
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
              if (masjid['description'] != null)
                Text(
                  masjid['description'],
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
                      masjid['address'] ?? 'No address',
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
                      onPressed: () => _rejectMasjid(masjid),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveMasjid(masjid),
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
                      onPressed: () => _suspendMasjid(masjid),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspend'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  if (status == 'suspended' || status == 'rejected')
                    ElevatedButton.icon(
                      onPressed: () => _approveMasjid(masjid),
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
