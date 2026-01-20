import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';
import 'package:munajat_e_maqbool_app/services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PaymentService _paymentService = PaymentService();

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _myRequests = [];
  Map<String, dynamic>? _currentPlan;
  Map<String, dynamic>? _selectedPlan;
  Map<String, dynamic>? _selectedPaymentMethod;
  File? _screenshotFile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _step = 0; // 0: view plans, 1: select payment, 2: upload screenshot

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final plans = await _subscriptionService.getPlans();
    final paymentMethods = await _paymentService.getPaymentMethods();
    final currentPlan = await _subscriptionService.getCurrentUserPlan();
    final myRequests = await _paymentService.getMyRequests();

    if (mounted) {
      setState(() {
        _plans = plans;
        _paymentMethods = paymentMethods;
        _currentPlan = currentPlan;
        _myRequests = myRequests;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _screenshotFile = File(image.path));
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedPlan == null ||
        _selectedPaymentMethod == null ||
        _screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _paymentService.submitSubscriptionRequest(
        planId: _selectedPlan!['id'],
        paymentMethodId: _selectedPaymentMethod!['id'],
        screenshotFile: _screenshotFile!,
        amount: (_selectedPlan!['price'] as num?)?.toDouble(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! Admin will review shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _step = 0;
          _selectedPlan = null;
          _selectedPaymentMethod = null;
          _screenshotFile = null;
        });
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
          title: 'Subscription',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Plan
                      _buildCurrentPlanCard(isDark, textColor, accentColor),
                      const SizedBox(height: 24),

                      // Pending Requests
                      if (_myRequests.any((r) => r['status'] == 'pending')) ...[
                        _buildPendingRequests(isDark, textColor, accentColor),
                        const SizedBox(height: 24),
                      ],

                      // Upgrade Flow
                      if (_step == 0) ...[
                        Text(
                          'Available Plans',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._plans.map(
                          (plan) => _buildPlanCard(
                            plan,
                            isDark,
                            textColor,
                            accentColor,
                          ),
                        ),
                      ] else if (_step == 1) ...[
                        _buildPaymentMethodStep(isDark, textColor, accentColor),
                      ] else if (_step == 2) ...[
                        _buildScreenshotStep(isDark, textColor, accentColor),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCurrentPlanCard(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final planName = _currentPlan?['name'] ?? 'Free';
    final isFree = (_currentPlan?['price'] ?? 0) == 0;

    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFree ? Icons.star_border : Icons.star,
                  color: isFree ? textColor : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        planName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (_currentPlan != null) ...[
              const SizedBox(height: 16),
              _buildLimitRow(
                'Max Shops',
                _currentPlan!['max_shops'],
                textColor,
              ),
              _buildLimitRow(
                'Max Images',
                _currentPlan!['max_images_per_shop'],
                textColor,
              ),
              _buildLimitRow(
                'Max Menu Items',
                _currentPlan!['max_menu_items_per_shop'],
                textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(String label, dynamic value, Color textColor) {
    final displayValue = value == -1 || value == null
        ? '∞ Unlimited'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequests(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final pending = _myRequests.where((r) => r['status'] == 'pending').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Requests',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...pending.map(
          (r) => GlassCard(
            isDark: isDark,
            borderRadius: 12,
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: Text(
                r['plan']?['name'] ?? 'Plan',
                style: TextStyle(color: textColor),
              ),
              subtitle: Text(
                'Awaiting admin review',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    Map<String, dynamic> plan,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final price = plan['price'] as num? ?? 0;
    final isCurrentPlan = _currentPlan?['id'] == plan['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        onTap: isCurrentPlan
            ? null
            : () {
                setState(() {
                  _selectedPlan = plan;
                  _step = 1;
                });
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] ?? 'Plan',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          price == 0
                              ? 'Free'
                              : '${price.toStringAsFixed(0)} MMK / ${plan['duration_days'] ?? 30} days',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    )
                  else if (price > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPlan = plan;
                          _step = 1;
                        });
                      },
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
              if (plan['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  plan['description'],
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => setState(() => _step = 0),
            ),
            Text(
              'Select Payment Method',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Upgrading to: ${_selectedPlan?['name']} - ${(_selectedPlan?['price'] ?? 0).toStringAsFixed(0)} MMK',
          style: TextStyle(color: accentColor, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map(
          (method) =>
              _buildPaymentMethodCard(method, isDark, textColor, accentColor),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isSelected = _selectedPaymentMethod?['id'] == method['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
            _step = 2;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: accentColor, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getProviderIcon(method['provider']),
                color: accentColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'] ?? 'Payment',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      method['account_number'] ?? '',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    if (method['account_name'] != null)
                      Text(
                        method['account_name'],
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

  Widget _buildScreenshotStep(bool isDark, Color textColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => setState(() => _step = 1),
            ),
            Text(
              'Upload Payment Screenshot',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment info
        GlassCard(
          isDark: isDark,
          borderRadius: 12,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Details',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ${(_selectedPlan?['price'] ?? 0).toStringAsFixed(0)} MMK',
                  style: TextStyle(color: accentColor),
                ),
                Text(
                  'Pay to: ${_selectedPaymentMethod?['name']}',
                  style: TextStyle(color: textColor),
                ),
                Text(
                  'Account: ${_selectedPaymentMethod?['account_number']}',
                  style: TextStyle(color: textColor),
                ),
                Text(
                  'Name: ${_selectedPaymentMethod?['account_name']}',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                ),
                if (_selectedPaymentMethod?['instructions'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _selectedPaymentMethod!['instructions'],
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Screenshot upload
        GestureDetector(
          onTap: _pickScreenshot,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: _screenshotFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_screenshotFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload screenshot',
                        style: TextStyle(color: accentColor),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _screenshotFile == null || _isSubmitting
                ? null
                : _submitRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: accentColor,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Request', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  IconData _getProviderIcon(String? provider) {
    switch (provider) {
      case 'kbzpay':
        return Icons.account_balance;
      case 'wavepay':
        return Icons.waves;
      case 'ayapay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
}
