import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopMenuService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== CATEGORIES ==========

  /// Get all categories for a shop
  Future<List<Map<String, dynamic>>> getCategories(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_menu_categories')
          .select()
          .eq('shop_id', shopId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetCategories Error: $e');
      return [];
    }
  }

  /// Create a new category
  Future<Map<String, dynamic>> createCategory({
    required String shopId,
    required String name,
    int displayOrder = 0,
  }) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_menu_categories')
          .insert({
            'shop_id': shopId,
            'name': name,
            'display_order': displayOrder,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('CreateCategory Error: $e');
      rethrow;
    }
  }

  /// Update a category
  Future<void> updateCategory({
    required String categoryId,
    String? name,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (updates.isEmpty) return;

    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_menu_categories')
          .update(updates)
          .eq('id', categoryId);
    } catch (e) {
      debugPrint('UpdateCategory Error: $e');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_menu_categories')
          .delete()
          .eq('id', categoryId);
    } catch (e) {
      debugPrint('DeleteCategory Error: $e');
      rethrow;
    }
  }

  // ========== MENU ITEMS ==========

  /// Get all menu items for a shop
  Future<List<Map<String, dynamic>>> getMenuItems(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .select('*, category:shop_menu_categories(name)')
          .eq('shop_id', shopId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetMenuItems Error: $e');
      return [];
    }
  }

  /// Get menu items by category
  Future<List<Map<String, dynamic>>> getMenuItemsByCategory(
    String categoryId,
  ) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .select()
          .eq('category_id', categoryId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetMenuItemsByCategory Error: $e');
      return [];
    }
  }

  /// Create a new menu item
  Future<Map<String, dynamic>> createMenuItem({
    required String shopId,
    String? categoryId,
    required String name,
    String? description,
    double? price,
    String? imageUrl,
    bool isAvailable = true,
    bool isHalalCertified = false,
    int displayOrder = 0,
  }) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .insert({
            'shop_id': shopId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'price': price,
            'image_url': imageUrl,
            'is_available': isAvailable,
            'is_halal_certified': isHalalCertified,
            'display_order': displayOrder,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('CreateMenuItem Error: $e');
      rethrow;
    }
  }

  /// Update a menu item
  Future<void> updateMenuItem({
    required String itemId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    bool? isHalalCertified,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (categoryId != null) updates['category_id'] = categoryId;
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isAvailable != null) updates['is_available'] = isAvailable;
    if (isHalalCertified != null) {
      updates['is_halal_certified'] = isHalalCertified;
    }
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (updates.isEmpty) return;

    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .update(updates)
          .eq('id', itemId);
    } catch (e) {
      debugPrint('UpdateMenuItem Error: $e');
      rethrow;
    }
  }

  /// Toggle item availability
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .update({'is_available': isAvailable})
          .eq('id', itemId);
    } catch (e) {
      debugPrint('ToggleAvailability Error: $e');
      rethrow;
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      debugPrint('DeleteMenuItem Error: $e');
      rethrow;
    }
  }

  /// Get full menu with categories and items grouped
  Future<List<Map<String, dynamic>>> getFullMenu(String shopId) async {
    try {
      final categories = await getCategories(shopId);
      final items = await getMenuItems(shopId);

      // Group items by category
      final result = <Map<String, dynamic>>[];

      for (final category in categories) {
        final categoryId = category['id'];
        final categoryItems = items
            .where((item) => item['category_id'] == categoryId)
            .toList();

        result.add({...category, 'items': categoryItems});
      }

      // Add uncategorized items
      final uncategorized = items
          .where((item) => item['category_id'] == null)
          .toList();
      if (uncategorized.isNotEmpty) {
        result.add({'id': null, 'name': 'Other Items', 'items': uncategorized});
      }

      return result;
    } catch (e) {
      debugPrint('GetFullMenu Error: $e');
      return [];
    }
  }
}
