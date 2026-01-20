import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';

class PlanManagementScreen extends StatefulWidget {
  const PlanManagementScreen({super.key});

  @override
  State<PlanManagementScreen> createState() => _PlanManagementScreenState();
}

class _PlanManagementScreenState extends State<PlanManagementScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await _subscriptionService.getAllPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final nameController = TextEditingController(text: plan?['name'] ?? '');
    final descController = TextEditingController(
      text: plan?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: (plan?['price'] ?? 0).toString(),
    );
    final daysController = TextEditingController(
      text: (plan?['duration_days'] ?? 30).toString(),
    );
    int maxShops = plan?['max_shops'] ?? 1;
    int maxImages = plan?['max_images_per_shop'] ?? 3;
    int maxMenuItems = plan?['max_menu_items_per_shop'] ?? 10;
    bool showBadge = plan?['show_premium_badge'] ?? false;
    bool priorityListing = plan?['priority_listing'] ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Plan' : 'Create Plan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Plan Name *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price (MMK)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: daysController,
                          decoration: const InputDecoration(labelText: 'Days'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Limits (-1 = unlimited)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLimitSlider(
                    'Max Shops',
                    maxShops,
                    (v) => setDialogState(() => maxShops = v),
                  ),
                  _buildLimitSlider(
                    'Max Images/Shop',
                    maxImages,
                    (v) => setDialogState(() => maxImages = v),
                  ),
                  _buildLimitSlider(
                    'Max Menu Items',
                    maxMenuItems,
                    (v) => setDialogState(() => maxMenuItems = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Premium Badge'),
                    value: showBadge,
                    onChanged: (v) => setDialogState(() => showBadge = v),
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('Priority Listing'),
                    value: priorityListing,
                    onChanged: (v) => setDialogState(() => priorityListing = v),
                    dense: true,
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
                child: Text(isEdit ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final planData = {
        'name': nameController.text,
        'description': descController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'duration_days': int.tryParse(daysController.text) ?? 30,
        'max_shops': maxShops,
        'max_images_per_shop': maxImages,
        'max_menu_items_per_shop': maxMenuItems,
        'show_premium_badge': showBadge,
        'priority_listing': priorityListing,
      };

      try {
        if (isEdit) {
          await _subscriptionService.updatePlan(plan['id'], planData);
        } else {
          await _subscriptionService.createPlan(planData);
        }
        await _loadPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Plan updated!' : 'Plan created!'),
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

  Widget _buildLimitSlider(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(-1, 100).toDouble(),
            min: -1,
            max: 100,
            divisions: 101,
            label: value == -1 ? '∞' : value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value == -1 ? '∞' : value.toString(),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _setDefault(Map<String, dynamic> plan) async {
    try {
      await _subscriptionService.setDefaultPlan(plan['id']);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default plan updated!'),
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

  Future<void> _toggleStatus(Map<String, dynamic> plan) async {
    try {
      await _subscriptionService.togglePlanStatus(
        plan['id'],
        !plan['is_active'],
      );
      await _loadPlans();
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
          title: 'Subscription Plans',
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () => _showPlanDialog(),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.subscriptions,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No plans yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showPlanDialog(),
                        child: const Text('Create Plan'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanCard(
                        plan,
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

  Widget _buildPlanCard(
    Map<String, dynamic> plan,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isActive = plan['is_active'] as bool? ?? true;
    final isDefault = plan['is_default'] as bool? ?? false;
    final price = plan['price'] as num? ?? 0;

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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan['name'] ?? 'Plan',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'INACTIVE',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price == 0
                              ? 'Free'
                              : '${price.toStringAsFixed(0)} MMK/${plan['duration_days']} days',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showPlanDialog(plan: plan);
                          break;
                        case 'default':
                          _setDefault(plan);
                          break;
                        case 'toggle':
                          _toggleStatus(plan);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set as Default'),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ],
                  ),
                ],
              ),
              if (plan['description'] != null &&
                  (plan['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan['description'],
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildLimitChip(
                    'Shops: ${_formatLimit(plan['max_shops'])}',
                    textColor,
                  ),
                  _buildLimitChip(
                    'Images: ${_formatLimit(plan['max_images_per_shop'])}',
                    textColor,
                  ),
                  _buildLimitChip(
                    'Menu: ${_formatLimit(plan['max_menu_items_per_shop'])}',
                    textColor,
                  ),
                  if (plan['show_premium_badge'] == true)
                    _buildLimitChip('⭐ Badge', textColor),
                  if (plan['priority_listing'] == true)
                    _buildLimitChip('🔝 Priority', textColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLimit(dynamic value) {
    if (value == null || value == -1) return '∞';
    return value.toString();
  }

  Widget _buildLimitChip(String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11)),
    );
  }
}
