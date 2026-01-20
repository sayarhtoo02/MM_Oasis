import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_image_manager.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_menu_editor.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_location_picker.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/operating_hours_editor.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_orders_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_payment_settings_screen.dart';

class ShopEditScreen extends StatefulWidget {
  final String shopId;

  const ShopEditScreen({super.key, required this.shopId});

  @override
  State<ShopEditScreen> createState() => _ShopEditScreenState();
}

class _ShopEditScreenState extends State<ShopEditScreen> {
  final ShopService _shopService = ShopService();
  Map<String, dynamic>? _shop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() => _isLoading = true);
    final shop = await _shopService.getShopById(widget.shopId);
    if (mounted) {
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
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

        if (_isLoading) {
          return GlassScaffold(
            title: 'Shop Details',
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (_shop == null) {
          return GlassScaffold(
            title: 'Shop Details',
            body: Center(
              child: Text('Shop not found', style: TextStyle(color: textColor)),
            ),
          );
        }

        final status = _shop!['status'] as String? ?? 'pending';
        final statusColor = _getStatusColor(status);

        return GlassScaffold(
          title: _shop!['name'] ?? 'Shop Details',
          body: RefreshIndicator(
            onRefresh: _loadShop,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          status == 'approved'
                              ? Icons.check_circle
                              : status == 'rejected'
                              ? Icons.cancel
                              : Icons.hourglass_empty,
                          color: statusColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${status.toUpperCase()}',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_shop!['rejection_reason'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _shop!['rejection_reason'],
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Management Options
                  Text(
                    'Manage Your Shop',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildManagementTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Info',
                    subtitle: 'Update name, description, and contact details',
                    onTap: () =>
                        _showEditInfoDialog(isDark, textColor, accentColor),
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Images',
                    subtitle: 'Manage logo, cover, and gallery photos',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopImageManager(
                          shopId: widget.shopId,
                          shopName: _shop!['name'] ?? '',
                        ),
                      ),
                    ),
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Menu',
                    subtitle: 'Add categories, items, and prices',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopMenuEditor(
                          shopId: widget.shopId,
                          shopName: _shop!['name'] ?? '',
                        ),
                      ),
                    ),
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle: 'Update shop location on map',
                    onTap: () async {
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopLocationPicker(
                            initialLat: _shop!['lat'] as double?,
                            initialLng: _shop!['long'] as double?,
                          ),
                        ),
                      );
                      if (result != null) {
                        await _shopService.updateShop(
                          shopId: widget.shopId,
                          lat: result['lat'] as double?,
                          long: result['lng'] as double?,
                          address: result['address'] as String?,
                        );
                        await _loadShop();
                      }
                    },
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.access_time_outlined,
                    title: 'Operating Hours',
                    subtitle: 'Set your opening and closing times',
                    onTap: () async {
                      final currentHours =
                          _shop!['operating_hours'] as Map<String, dynamic>? ??
                          {};
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OperatingHoursEditor(
                            initialHours: currentHours,
                            onSave: (hours) async {
                              await _shopService.updateShop(
                                shopId: widget.shopId,
                                operatingHours: hours,
                              );
                              await _loadShop();
                            },
                          ),
                        ),
                      );
                    },
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Orders',
                    subtitle: 'View and manage customer orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopOrdersScreen(
                          shopId: widget.shopId,
                          shopName: _shop!['name'] ?? '',
                        ),
                      ),
                    ),
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  _buildManagementTile(
                    icon: Icons.payment_outlined,
                    title: 'Payment Settings',
                    subtitle: 'Configure payment methods for orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopPaymentSettingsScreen(
                          shopId: widget.shopId,
                          shopName: _shop!['name'] ?? '',
                        ),
                      ),
                    ),
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  const SizedBox(height: 24),

                  // Shop Info
                  Text(
                    'Shop Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow('Address', _shop!['address'], textColor),
                  _buildInfoRow('Phone', _shop!['contact_phone'], textColor),
                  _buildInfoRow('Email', _shop!['contact_email'], textColor),
                  _buildInfoRow('Website', _shop!['website'], textColor),
                  _buildInfoRow('Category', _shop!['category'], textColor),

                  const SizedBox(height: 24),

                  // Action Buttons based on status
                  if (status == 'rejected') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showResubmitDialog(accentColor),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Resubmit for Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete Shop',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
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
                child: Icon(icon, color: accentColor),
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
                    const SizedBox(height: 2),
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

  Widget _buildInfoRow(String label, String? value, Color textColor) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditInfoDialog(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) async {
    final nameController = TextEditingController(text: _shop!['name'] ?? '');
    final descriptionController = TextEditingController(
      text: _shop!['description'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _shop!['contact_phone'] ?? '',
    );
    final emailController = TextEditingController(
      text: _shop!['contact_email'] ?? '',
    );
    final websiteController = TextEditingController(
      text: _shop!['website'] ?? '',
    );
    final deliveryRangeController = TextEditingController(
      text: _shop!['delivery_range'] ?? '',
    );
    bool isDeliveryAvailable = _shop!['is_delivery_available'] ?? false;
    double deliveryRadiusKm =
        (_shop!['delivery_radius_km'] as num?)?.toDouble() ?? 5.0;
    String selectedCategory = _shop!['category'] ?? 'restaurant';

    final categories = [
      'restaurant',
      'grocery',
      'bakery',
      'butcher',
      'cafe',
      'other',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Shop Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c[0].toUpperCase() + c.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(
                    () => selectedCategory = v ?? 'restaurant',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Delivery Settings
                SwitchListTile(
                  title: const Text('Delivery Available'),
                  value: isDeliveryAvailable,
                  onChanged: (val) =>
                      setDialogState(() => isDeliveryAvailable = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isDeliveryAvailable) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: deliveryRangeController,
                    decoration: const InputDecoration(
                      labelText:
                          'Delivery Description (e.g., 5 miles, Downtown)',
                      border: OutlineInputBorder(),
                      helperText: 'Text description for users',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delivery Radius: ${deliveryRadiusKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: deliveryRadiusKm,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    label: '${deliveryRadiusKm.toStringAsFixed(1)} km',
                    onChanged: (val) =>
                        setDialogState(() => deliveryRadiusKm = val),
                  ),
                ],
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _shopService.updateShop(
          shopId: widget.shopId,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          contactPhone: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          contactEmail: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          website: websiteController.text.trim().isEmpty
              ? null
              : websiteController.text.trim(),
          category: selectedCategory,
          isDeliveryAvailable: isDeliveryAvailable,
          deliveryRange: isDeliveryAvailable
              ? deliveryRangeController.text.trim().isEmpty
                    ? null
                    : deliveryRangeController.text.trim()
              : null,
          deliveryRadiusKm: isDeliveryAvailable ? deliveryRadiusKm : null,
        );
        await _loadShop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop info updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating shop: $e')));
        }
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text(
          'Are you sure you want to delete this shop? '
          'This will permanently remove all shop data including images, menu items, and reviews. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _shopService.deleteShop(widget.shopId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting shop: $e')));
        }
      }
    }
  }

  Future<void> _showResubmitDialog(Color accentColor) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit for Review'),
        content: const Text(
          'Your shop will be resubmitted for admin review. '
          'Make sure you have addressed the rejection reason before resubmitting. '
          'Would you like to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _shopService.resubmitShop(widget.shopId);
        await _loadShop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop resubmitted for review!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resubmitting shop: $e')),
          );
        }
      }
    }
  }
}
