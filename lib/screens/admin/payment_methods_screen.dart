import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/payment_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _methods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _isLoading = true);
    final methods = await _paymentService.getAllPaymentMethods();
    if (mounted) {
      setState(() {
        _methods = methods;
        _isLoading = false;
      });
    }
  }

  Future<void> _showMethodDialog({Map<String, dynamic>? method}) async {
    final isEdit = method != null;
    final nameController = TextEditingController(text: method?['name'] ?? '');
    final providerController = TextEditingController(
      text: method?['provider'] ?? '',
    );
    final accountNameController = TextEditingController(
      text: method?['account_name'] ?? '',
    );
    final accountNumberController = TextEditingController(
      text: method?['account_number'] ?? '',
    );
    final instructionsController = TextEditingController(
      text: method?['instructions'] ?? '',
    );
    bool isActive = method?['is_active'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name *',
                      hintText: 'e.g., KBZ Pay',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: providerController,
                    decoration: const InputDecoration(
                      labelText: 'Provider Code *',
                      hintText: 'e.g., kbzpay',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Name *',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number *',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final data = {
        'name': nameController.text,
        'provider': providerController.text.toLowerCase().replaceAll(' ', ''),
        'account_name': accountNameController.text,
        'account_number': accountNumberController.text,
        'instructions': instructionsController.text,
        'is_active': isActive,
      };

      try {
        if (isEdit) {
          await _paymentService.updatePaymentMethod(method['id'], data);
        } else {
          await _paymentService.createPaymentMethod(data);
        }
        await _loadMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Updated!' : 'Added!'),
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
  }

  Future<void> _deleteMethod(Map<String, dynamic> method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${method['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.deletePaymentMethod(method['id']);
        await _loadMethods();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
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
          title: 'Payment Methods',
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () => _showMethodDialog(),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _methods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showMethodDialog(),
                        child: const Text('Add Method'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMethods,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _methods.length,
                    itemBuilder: (context, index) {
                      final method = _methods[index];
                      return _buildMethodCard(
                        method,
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

  Widget _buildMethodCard(
    Map<String, dynamic> method,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isActive = method['is_active'] as bool? ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        onTap: () => _showMethodDialog(method: method),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.account_balance, color: accentColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method['name'] ?? 'Method',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(color: Colors.grey, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${method['account_name']} - ${method['account_number']}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteMethod(method),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
