import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_text_field.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_location_picker.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/subscription_screen.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _deliveryRangeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDeliveryAvailable = false;
  double _deliveryRadius = 1.0;

  // Location data
  double? _lat;
  double? _lng;

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ShopLocationPicker(initialLat: _lat, initialLng: _lng),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lat = result['lat'] as double?;
        _lng = result['lng'] as double?;
        _addressController.text = result['address'] as String? ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select shop location on map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Check subscription limit
    final canAdd = await SubscriptionService().canAddShop();
    if (!canAdd) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showUpgradeDialog();
      }
      return;
    }

    try {
      await ShopService().createShop(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        website: _websiteController.text.trim(),
        lat: _lat,
        long: _lng,
        isDeliveryAvailable: _isDeliveryAvailable,
        deliveryRange: _isDeliveryAvailable
            ? _deliveryRangeController.text.trim()
            : null,
        deliveryRadiusKm: _isDeliveryAvailable ? _deliveryRadius : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Shop submitted for approval! We\'ll review it shortly.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to register shop: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text(
          'You have reached the maximum number of shops for your current plan. Please upgrade to add more shops.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _websiteController.dispose();
    _deliveryRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Register Shop',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your shop will be reviewed by admin before appearing to users.',
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Basic Info
                  Text(
                    'Basic Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _nameController,
                    hintText: 'Shop Name *',
                    icon: Icons.store_outlined,
                    isDark: isDark,
                    validator: (v) =>
                        v!.isEmpty ? 'Shop name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _descController,
                    hintText: 'Description *',
                    icon: Icons.description_outlined,
                    isDark: isDark,
                    maxLines: 3,
                    validator: (v) =>
                        v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Section: Location
                  Text(
                    'Location',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    isDark: isDark,
                    borderRadius: 12,
                    onTap: _pickLocation,
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
                            child: Icon(
                              _lat != null
                                  ? Icons.check_circle
                                  : Icons.add_location_alt,
                              color: _lat != null ? Colors.green : accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lat != null
                                      ? 'Location Selected'
                                      : 'Select Location on Map *',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_lat != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _addressController,
                    hintText: 'Full Address *',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Section: Contact
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _contactPhoneController,
                    hintText: 'Phone Number *',
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _contactEmailController,
                    hintText: 'Email (optional)',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _websiteController,
                    hintText: 'Website (optional)',
                    icon: Icons.language_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),

                  // Section: Delivery
                  Text(
                    'Delivery Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Delivery Available',
                            style: TextStyle(color: textColor),
                          ),
                          value: _isDeliveryAvailable,
                          onChanged: (val) =>
                              setState(() => _isDeliveryAvailable = val),
                          activeThumbColor: accentColor,
                        ),
                        if (_isDeliveryAvailable) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlassTextField(
                                  controller: _deliveryRangeController,
                                  hintText:
                                      'Delivery Description (e.g. 5 miles)',
                                  icon: Icons.description_outlined,
                                  isDark: isDark,
                                  validator: (v) =>
                                      _isDeliveryAvailable &&
                                          (v == null || v.isEmpty)
                                      ? 'Delivery description is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Slider(
                                  value: _deliveryRadius,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  label:
                                      '${_deliveryRadius.toStringAsFixed(1)} km',
                                  onChanged: (val) =>
                                      setState(() => _deliveryRadius = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit for Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
