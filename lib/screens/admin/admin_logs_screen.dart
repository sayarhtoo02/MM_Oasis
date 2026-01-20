import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _adminService.getAdminLogs(limit: 100);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  IconData _getActionIcon(String? actionType) {
    switch (actionType) {
      case 'approve_shop':
        return Icons.check_circle;
      case 'reject_shop':
        return Icons.cancel;
      case 'suspend_shop':
        return Icons.block;
      case 'reactivate_shop':
        return Icons.restore;
      case 'update_user_role':
        return Icons.admin_panel_settings;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String? actionType) {
    switch (actionType) {
      case 'approve_shop':
      case 'reactivate_shop':
        return Colors.green;
      case 'reject_shop':
        return Colors.red;
      case 'suspend_shop':
        return Colors.grey;
      case 'update_user_role':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatActionType(String? actionType) {
    if (actionType == null) return 'Unknown';
    return actionType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Admin Logs',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: _loadLogs,
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _logs.isEmpty
              ? Center(
                  child: Text(
                    'No logs found',
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogCard(log, isDark, textColor);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark, Color textColor) {
    final actionType = log['action_type'] as String?;
    final actionColor = _getActionColor(actionType);
    final actionIcon = _getActionIcon(actionType);
    final admin = log['admin'] as Map<String, dynamic>?;
    final createdAt = log['created_at'] != null
        ? DateTime.parse(log['created_at'])
        : DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        isDarkForce: isDark,
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatActionType(actionType),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${admin?['username'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    if (log['notes'] != null &&
                        (log['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        log['notes'],
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, HH:mm').format(createdAt),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
