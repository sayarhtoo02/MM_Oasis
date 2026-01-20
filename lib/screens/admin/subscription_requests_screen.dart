import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/payment_service.dart';

class SubscriptionRequestsScreen extends StatefulWidget {
  const SubscriptionRequestsScreen({super.key});

  @override
  State<SubscriptionRequestsScreen> createState() =>
      _SubscriptionRequestsScreenState();
}

class _SubscriptionRequestsScreenState
    extends State<SubscriptionRequestsScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> requests;
    if (_filter == 'pending') {
      requests = await _paymentService.getPendingRequests();
    } else {
      requests = await _paymentService.getAllRequests();
    }

    if (mounted) {
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    try {
      await _paymentService.approveRequest(request['id']);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approved!'),
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

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Invalid payment screenshot',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.rejectRequest(
          request['id'],
          reason: reasonController.text,
        );
        await _loadRequests();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rejected')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _viewScreenshot(String? url) {
    if (url == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Failed to load image')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Subscription Requests',
          actions: [
            PopupMenuButton<String>(
              initialValue: _filter,
              onSelected: (value) {
                setState(() => _filter = value);
                _loadRequests();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pending',
                  child: Text('Pending Only'),
                ),
                const PopupMenuItem(value: 'all', child: Text('All Requests')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      _filter == 'pending' ? 'Pending' : 'All',
                      style: TextStyle(color: textColor),
                    ),
                    Icon(Icons.arrow_drop_down, color: textColor),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'pending'
                            ? 'No pending requests'
                            : 'No requests yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return _buildRequestCard(
                        request,
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

  Widget _buildRequestCard(
    Map<String, dynamic> request,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final status = request['status'] as String? ?? 'pending';
    final createdAt = request['created_at'] != null
        ? DateFormat(
            'MMM d, y HH:mm',
          ).format(DateTime.parse(request['created_at']))
        : '';
    final username =
        request['user_profile']?['username'] ??
        request['user_profile']?['email'] ??
        'User';
    final planName = request['plan']?['name'] ?? 'Plan';
    final amount = request['amount'] ?? request['plan']?['price'] ?? 0;
    final paymentMethod = request['payment_method']?['name'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          createdAt,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
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

              const Divider(height: 24),

              // Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan: $planName',
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          'Amount: ${(amount as num).toStringAsFixed(0)} MMK',
                          style: TextStyle(color: accentColor),
                        ),
                        Text(
                          'Via: $paymentMethod',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Screenshot preview
                  GestureDetector(
                    onTap: () => _viewScreenshot(request['screenshot_url']),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: request['screenshot_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                request['screenshot_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.image, color: accentColor),
                              ),
                            )
                          : Icon(Icons.image, color: accentColor),
                    ),
                  ),
                ],
              ),

              // Actions for pending
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectRequest(request),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveRequest(request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],

              // Admin notes for rejected
              if (status == 'rejected' && request['admin_notes'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${request['admin_notes']}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
