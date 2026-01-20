import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';

import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_menu_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/subscription_screen.dart';

class ShopMenuEditor extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopMenuEditor({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopMenuEditor> createState() => _ShopMenuEditorState();
}

class _ShopMenuEditorState extends State<ShopMenuEditor> {
  final ShopMenuService _menuService = ShopMenuService();
  List<Map<String, dynamic>> _menu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final menu = await _menuService.getFullMenu(widget.shopId);
    if (mounted) {
      setState(() {
        _menu = menu;
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final name = await _showTextInputDialog('New Category', 'Category Name');
    if (name == null || name.isEmpty) return;

    try {
      await _menuService.createCategory(
        shopId: widget.shopId,
        name: name,
        displayOrder: _menu.length,
      );
      await _loadMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final name = await _showTextInputDialog(
      'Edit Category',
      'Category Name',
      initialValue: category['name'],
    );
    if (name == null || name.isEmpty) return;

    try {
      await _menuService.updateCategory(categoryId: category['id'], name: name);
      await _loadMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
          'All items in this category will become uncategorized.',
        ),
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
      await _menuService.deleteCategory(categoryId);
      await _loadMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMenuItem(String? categoryId) async {
    // Check subscription limit
    final canAdd = await SubscriptionService().canAddMenuItem(widget.shopId);
    if (!canAdd) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    await _showMenuItemDialog(categoryId: categoryId);
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text(
          'You have reached the maximum number of menu items for your current plan. Please upgrade to add more items.',
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

  Future<void> _editMenuItem(Map<String, dynamic> item) async {
    await _showMenuItemDialog(existingItem: item);
  }

  Future<void> _deleteMenuItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
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
      await _menuService.deleteMenuItem(itemId);
      await _loadMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _showTextInputDialog(
    String title,
    String hint, {
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMenuItemDialog({
    String? categoryId,
    Map<String, dynamic>? existingItem,
  }) async {
    final nameController = TextEditingController(
      text: existingItem?['name'] ?? '',
    );
    final descController = TextEditingController(
      text: existingItem?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: existingItem?['price']?.toString() ?? '',
    );
    bool isAvailable = existingItem?['is_available'] ?? true;
    bool isHalalCertified = existingItem?['is_halal_certified'] ?? false;
    String? imageUrl = existingItem?['image_url'];
    File? selectedImage;
    bool isUploading = false;

    final imageService = ShopImageService();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existingItem != null ? 'Edit Item' : 'Add Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Section
                  GestureDetector(
                    onTap: () async {
                      final file = await imageService.pickImageFromGallery();
                      if (file != null) {
                        setDialogState(() => selectedImage = file);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      'Image error',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (K)',
                      border: OutlineInputBorder(),
                      prefixText: 'K ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Available'),
                    value: isAvailable,
                    onChanged: (v) =>
                        setDialogState(() => isAvailable = v ?? true),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Halal Certified'),
                    value: isHalalCertified,
                    onChanged: (v) =>
                        setDialogState(() => isHalalCertified = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name is required')),
                          );
                          return;
                        }

                        setDialogState(() => isUploading = true);

                        // Upload image if selected
                        String? finalImageUrl = imageUrl;
                        if (selectedImage != null) {
                          try {
                            finalImageUrl = await imageService.uploadImage(
                              file: selectedImage!,
                              shopId: widget.shopId,
                              imageType: 'menu_item',
                            );
                          } catch (e) {
                            debugPrint('Image upload error: $e');
                          }
                        }

                        if (!context.mounted) return;

                        Navigator.pop(context, {
                          'name': nameController.text,
                          'description': descController.text,
                          'price': priceController.text,
                          'isAvailable': isAvailable,
                          'isHalalCertified': isHalalCertified,
                          'imageUrl': finalImageUrl,
                        });
                      },
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    try {
      if (existingItem != null) {
        await _menuService.updateMenuItem(
          itemId: existingItem['id'],
          name: result['name'],
          description: result['description']?.isEmpty == true
              ? null
              : result['description'],
          price: double.tryParse(result['price'] ?? ''),
          isAvailable: result['isAvailable'],
          isHalalCertified: result['isHalalCertified'],
          imageUrl: result['imageUrl'],
        );
      } else {
        await _menuService.createMenuItem(
          shopId: widget.shopId,
          categoryId: categoryId,
          name: result['name'],
          description: result['description']?.isEmpty == true
              ? null
              : result['description'],
          price: double.tryParse(result['price'] ?? ''),
          isAvailable: result['isAvailable'],
          isHalalCertified: result['isHalalCertified'],
          imageUrl: result['imageUrl'],
        );
      }
      await _loadMenu();
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
          title: 'Menu Editor',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addCategory,
            backgroundColor: accentColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _menu.isEmpty
              ? _buildEmptyState(textColor, accentColor)
              : RefreshIndicator(
                  onRefresh: _loadMenu,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menu.length,
                    itemBuilder: (context, index) {
                      final category = _menu[index];
                      return _buildCategorySection(
                        category,
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

  Widget _buildEmptyState(Color textColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 80,
            color: textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items yet',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add categories and items to build your menu',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    Map<String, dynamic> category,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final items = category['items'] as List? ?? [];
    final categoryId = category['id'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            children: [
              Expanded(
                child: Text(
                  category['name'] as String,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (categoryId != null) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: textColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () => _editCategory(category),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onPressed: () => _deleteCategory(categoryId),
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: accentColor,
                  size: 24,
                ),
                onPressed: () => _addMenuItem(categoryId),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No items in this category',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.map(
              (item) => _buildMenuItem(item, isDark, textColor, accentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    Map<String, dynamic> item,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isAvailable = item['is_available'] as bool? ?? true;
    final isHalal = item['is_halal_certified'] as bool? ?? false;
    final price = item['price'];
    final imageUrl = item['image_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 16,
        onTap: () => _editMenuItem(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.restaurant,
                            color: textColor.withValues(alpha: 0.3),
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: textColor.withValues(alpha: 0.3),
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: TextStyle(
                              color: isAvailable
                                  ? textColor
                                  : textColor.withValues(alpha: 0.4),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isAvailable
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (isHalal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'HALAL',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (item['description'] != null &&
                        (item['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['description'] as String,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'K ${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          children: [
                            if (!isAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _deleteMenuItem(item['id']),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
