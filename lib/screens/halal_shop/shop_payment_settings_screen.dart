import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/order_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';

class ShopPaymentSettingsScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopPaymentSettingsScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopPaymentSettingsScreen> createState() =>
      _ShopPaymentSettingsScreenState();
}

class _ShopPaymentSettingsScreenState extends State<ShopPaymentSettingsScreen> {
  final OrderService _orderService = OrderService();
  final ShopImageService _imageService = ShopImageService();

  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;

  final List<String> _methodTypes = [
    'bank',
    'kpay',
    'wavepay',
    'ayapay',
    'cbpay',
    'okdollar',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    final methods = await _orderService.getShopPaymentMethods(widget.shopId);
    if (mounted) {
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    }
  }

  Future<void> _addPaymentMethod() async {
    String? selectedType;
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    File? qrCodeFile;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Type *',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedType,
                  items: _methodTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number / Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final file = await _imageService.pickImageFromGallery();
                    if (file != null) {
                      setDialogState(() => qrCodeFile = file);
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: qrCodeFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(qrCodeFile!, fit: BoxFit.contain),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add QR Code',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
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
              onPressed: selectedType == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true || selectedType == null) return;

    setState(() => _isLoading = true);

    try {
      await _orderService.addPaymentMethod(
        shopId: widget.shopId,
        methodType: selectedType!,
        accountName: nameController.text.isEmpty ? null : nameController.text,
        accountNumber: numberController.text.isEmpty
            ? null
            : numberController.text,
        qrCodeFile: qrCodeFile,
        displayOrder: _paymentMethods.length,
      );
      await _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment method added')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deletePaymentMethod(String methodId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _orderService.deletePaymentMethod(methodId);
      await _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment method deleted')));
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
          title: 'Payment Settings',
          floatingActionButton: FloatingActionButton(
            onPressed: _addPaymentMethod,
            backgroundColor: accentColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
            child: const Icon(Icons.add),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _paymentMethods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 60,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add payment methods so customers\ncan pay for their orders',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    return _buildPaymentMethodCard(
                      method,
                      isDark,
                      textColor,
                      accentColor,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(method['method_type']),
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (method['method_type'] as String).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePaymentMethod(method['id']),
                  ),
                ],
              ),
              if (method['account_name'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Name: ${method['account_name']}',
                  style: TextStyle(color: textColor),
                ),
              ],
              if (method['account_number'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Number: ${method['account_number']}',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (method['qr_code_url'] != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    method['qr_code_url'],
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'kpay':
      case 'wavepay':
      case 'ayapay':
      case 'cbpay':
      case 'okdollar':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }
}
