import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper to enrich shops with owner's subscription info
  Future<List<Map<String, dynamic>>> _enrichShopsWithSubscription(
    List<Map<String, dynamic>> shops,
  ) async {
    if (shops.isEmpty) return shops;

    try {
      final ownerIds = shops
          .map((s) => s['owner_id'] as String)
          .toSet()
          .toList();

      // Fetch profiles with correct column names
      final profilesResponse = await _supabase
          .schema('munajat_app')
          .from('profiles')
          .select('id, plan_id, subscription_expires_at')
          .filter('id', 'in', ownerIds);
      final profiles = List<Map<String, dynamic>>.from(profilesResponse);
      final profilesMap = {for (var p in profiles) p['id']: p};

      // Fetch plans
      final planIds = profiles
          .map((p) => p['plan_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, dynamic> plansMap = {};
      if (planIds.isNotEmpty) {
        final plansResponse = await _supabase
            .schema('munajat_app')
            .from('subscription_plans')
            .select()
            .filter('id', 'in', planIds);
        final plans = List<Map<String, dynamic>>.from(plansResponse);
        plansMap = {for (var p in plans) p['id']: p};
      }

      // Merge data
      return shops.map((shop) {
        final newShop = Map<String, dynamic>.from(shop);
        final ownerId = shop['owner_id'];
        final profile = profilesMap[ownerId];

        if (profile != null) {
          final planId = profile['plan_id'];
          final plan = plansMap[planId];
          final expiresAt = profile['subscription_expires_at'];

          // Check if subscription is active (not expired)
          bool isActive = false;
          if (expiresAt != null) {
            final expiry = DateTime.parse(expiresAt);
            isActive = expiry.isAfter(DateTime.now());
          }

          newShop['subscription_status'] = isActive ? 'active' : 'expired';
          if (plan != null) {
            newShop['subscription_plan'] = plan;
            newShop['is_pro'] =
                (plan['show_premium_badge'] == true) && isActive;
            newShop['priority_listing'] =
                (plan['priority_listing'] == true) && isActive;
          }
        }
        // Default values
        newShop['is_pro'] ??= false;
        newShop['priority_listing'] ??= false;
        return newShop;
      }).toList();
    } catch (e) {
      debugPrint('EnrichShops Error: $e');
      return shops; // Return original on error
    }
  }

  /// Fetch all approved shops (visible to users)
  Future<List<Map<String, dynamic>>> getShops() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final shops = List<Map<String, dynamic>>.from(response);
      final enriched = await _enrichShopsWithSubscription(shops);

      // Sort by priority if needed
      enriched.sort((a, b) {
        final aPrio = (a['priority_listing'] == true) ? 1 : 0;
        final bPrio = (b['priority_listing'] == true) ? 1 : 0;
        if (bPrio != aPrio) return bPrio.compareTo(aPrio);
        return DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at']));
      });

      return enriched;
    } catch (e) {
      debugPrint('GetShops Error: $e');
      rethrow;
    }
  }

  /// Search approved shops by name or menu item
  Future<List<Map<String, dynamic>>> searchShops(String query) async {
    try {
      final searchPattern = '%$query%';

      // 1. Search by Shop Name
      final shopsByNameResponse = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('status', 'approved')
          .ilike('name', searchPattern);
      final shopsByName = List<Map<String, dynamic>>.from(shopsByNameResponse);

      // 2. Search by Menu Item Name
      final menuItemsResponse = await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .select('shop_id')
          .ilike('item_name', searchPattern);

      final shopIdsFromMenu = List<Map<String, dynamic>>.from(
        menuItemsResponse,
      ).map((e) => e['shop_id'] as String).toSet().toList();

      List<Map<String, dynamic>> shopsFromMenu = [];
      if (shopIdsFromMenu.isNotEmpty) {
        final shopsFromMenuResponse = await _supabase
            .schema('munajat_app')
            .from('shops')
            .select()
            .eq('status', 'approved')
            .filter('id', 'in', shopIdsFromMenu);
        shopsFromMenu = List<Map<String, dynamic>>.from(shopsFromMenuResponse);
      }

      // Deduplicate results
      final allShops = [...shopsByName, ...shopsFromMenu];
      final uniqueShopsMap = {for (var s in allShops) s['id']: s};

      final shops = uniqueShopsMap.values.toList();
      return await _enrichShopsWithSubscription(shops);
    } catch (e) {
      debugPrint('SearchShops Error: $e');
      return [];
    }
  }

  /// Fetch shops owned by current user (with any status)
  Future<List<Map<String, dynamic>>> getMyShops() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      final shops = List<Map<String, dynamic>>.from(response);
      return await _enrichShopsWithSubscription(shops);
    } catch (e) {
      debugPrint('GetMyShops Error: $e');
      rethrow;
    }
  }

  /// Fetch pending shops (for admin approval)
  Future<List<Map<String, dynamic>>> getPendingShops() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      final shops = List<Map<String, dynamic>>.from(response);
      return await _enrichShopsWithSubscription(shops);
    } catch (e) {
      debugPrint('GetPendingShops Error: $e');
      rethrow;
    }
  }

  /// Fetch a single shop by ID
  Future<Map<String, dynamic>?> getShopById(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('id', shopId)
          .maybeSingle();

      if (response == null) return null;

      final enrichedList = await _enrichShopsWithSubscription([response]);
      return enrichedList.first;
    } catch (e) {
      debugPrint('GetShopById Error: $e');
      rethrow;
    }
  }

  /// Create a new shop (status defaults to 'pending')
  Future<Map<String, dynamic>> createShop({
    required String name,
    required String description,
    required String address,
    String? contactPhone,
    String? contactEmail,
    String? website,
    double? lat,
    double? long,
    bool isDeliveryAvailable = false,
    String? deliveryRange,
    double? deliveryRadiusKm,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create shop');

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .insert({
            'owner_id': user.id,
            'name': name,
            'description': description,
            'address': address,
            'contact_phone': contactPhone,
            'contact_email': contactEmail,
            'website': website,
            'lat': lat,
            'long': long,
            'is_delivery_available': isDeliveryAvailable,
            'delivery_range': deliveryRange,
            'delivery_radius_km': deliveryRadiusKm ?? 5.0,
            'status': 'pending', // Default to pending for admin review
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('CreateShop Error: $e');
      rethrow;
    }
  }

  /// Update shop details
  Future<void> updateShop({
    required String shopId,
    String? name,
    String? description,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? website,
    double? lat,
    double? long,
    Map<String, dynamic>? openingHours,
    Map<String, dynamic>? operatingHours,
    String? category,
    bool? isDeliveryAvailable,
    String? deliveryRange,
    double? deliveryRadiusKm,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (address != null) updates['address'] = address;
    if (contactPhone != null) updates['contact_phone'] = contactPhone;
    if (contactEmail != null) updates['contact_email'] = contactEmail;
    if (website != null) updates['website'] = website;
    if (lat != null) updates['lat'] = lat;
    if (long != null) updates['long'] = long;
    if (openingHours != null) updates['opening_hours'] = openingHours;
    if (operatingHours != null) updates['operating_hours'] = operatingHours;
    if (category != null) updates['category'] = category;
    if (isDeliveryAvailable != null) {
      updates['is_delivery_available'] = isDeliveryAvailable;
    }
    if (deliveryRange != null) updates['delivery_range'] = deliveryRange;
    if (deliveryRadiusKm != null) {
      updates['delivery_radius_km'] = deliveryRadiusKm;
    }

    if (updates.isEmpty && !updates.containsKey('is_open')) return;

    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update(updates)
          .eq('id', shopId);
    } catch (e) {
      debugPrint('UpdateShop Error: $e');
      rethrow;
    }
  }

  /// Change shop open/closed status manually
  Future<void> toggleShopOpenStatus(String shopId, bool isOpen) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'is_open': isOpen})
          .eq('id', shopId);
    } catch (e) {
      debugPrint('ToggleShopOpenStatus Error: $e');
      rethrow;
    }
  }

  /// Check if a shop is currently open based on manual override and operating hours
  static bool isOpen(Map<String, dynamic>? shop) {
    if (shop == null) return false;

    // 1. Check manual override first
    final isManualOpen = shop['is_open'] as bool? ?? true;
    if (!isManualOpen) return false;

    // 2. Check operating hours
    final operatingHours = shop['operating_hours'] as Map<String, dynamic>?;
    if (operatingHours == null || operatingHours.isEmpty) {
      return true; // Default to open if not set
    }

    final now = DateTime.now();
    // 1 = Monday, 7 = Sunday
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    // Get today's config
    final dayName = dayNames[now.weekday - 1];
    final todayConfig = operatingHours[dayName];

    if (todayConfig == null) {
      return true; // Assume open if day not configured? Or false? Let's say true for MVP simplicity unless explicitly closed.
    }

    // Check if explicitly marked closed for the day
    if (todayConfig['isOpen'] == false) return false;

    // Check time range
    final openTime = todayConfig['open'] as String?;
    final closeTime = todayConfig['close'] as String?;

    if (openTime == null || closeTime == null) return true;

    try {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');

      final openDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(openParts[0]),
        int.parse(openParts[1]),
      );
      final closeDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(closeParts[0]),
        int.parse(closeParts[1]),
      );

      return now.isAfter(openDt) && now.isBefore(closeDt);
    } catch (e) {
      debugPrint('Error parsing operating hours: $e');
      return true; // Fallback to open on error
    }
  }

  // ========== ADMIN FUNCTIONS ==========

  /// Approve a shop (admin only)
  Future<void> approveShop(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'approved_by': user.id,
            'rejection_reason': null,
          })
          .eq('id', shopId);

      // Log admin action
      await _logAdminAction(
        actionType: 'approve',
        targetType: 'shop',
        targetId: shopId,
      );
    } catch (e) {
      debugPrint('ApproveShop Error: $e');
      rethrow;
    }
  }

  /// Reject a shop (admin only)
  Future<void> rejectShop(String shopId, String reason) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'rejected', 'rejection_reason': reason})
          .eq('id', shopId);

      // Log admin action
      await _logAdminAction(
        actionType: 'reject',
        targetType: 'shop',
        targetId: shopId,
        details: {'reason': reason},
      );
    } catch (e) {
      debugPrint('RejectShop Error: $e');
      rethrow;
    }
  }

  /// Suspend a shop (admin only)
  Future<void> suspendShop(String shopId, String reason) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'suspended', 'rejection_reason': reason})
          .eq('id', shopId);

      await _logAdminAction(
        actionType: 'suspend',
        targetType: 'shop',
        targetId: shopId,
        details: {'reason': reason},
      );
    } catch (e) {
      debugPrint('SuspendShop Error: $e');
      rethrow;
    }
  }

  /// Delete a shop (owner only)
  Future<void> deleteShop(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // First delete related data
      await _supabase
          .schema('munajat_app')
          .from('shop_images')
          .delete()
          .eq('shop_id', shopId);

      await _supabase
          .schema('munajat_app')
          .from('shop_menu_items')
          .delete()
          .eq('shop_id', shopId);

      await _supabase
          .schema('munajat_app')
          .from('shop_menu_categories')
          .delete()
          .eq('shop_id', shopId);

      await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .delete()
          .eq('shop_id', shopId);

      // Then delete the shop
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .delete()
          .eq('id', shopId)
          .eq(
            'owner_id',
            user.id,
          ); // Ensure owner can only delete their own shops
    } catch (e) {
      debugPrint('DeleteShop Error: $e');
      rethrow;
    }
  }

  /// Resubmit a rejected shop for review
  Future<void> resubmitShop(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'pending', 'rejection_reason': null})
          .eq('id', shopId)
          .eq(
            'owner_id',
            user.id,
          ); // Ensure owner can only resubmit their own shops
    } catch (e) {
      debugPrint('ResubmitShop Error: $e');
      rethrow;
    }
  }

  /// Log admin action to audit table
  Future<void> _logAdminAction({
    required String actionType,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.schema('munajat_app').from('admin_actions').insert({
        'admin_id': user.id,
        'action_type': actionType,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
      });
    } catch (e) {
      debugPrint('LogAdminAction Error: $e');
    }
  }
}
