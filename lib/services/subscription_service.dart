import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active subscription plans
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetPlans Error: $e');
      return [];
    }
  }

  /// Get all plans (for admin) - uses service role
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    try {
      final response = await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .select()
          .order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllPlans Error: $e');
      return [];
    }
  }

  /// Get default plan
  Future<Map<String, dynamic>?> getDefaultPlan() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('subscription_plans')
          .select()
          .eq('is_default', true)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('GetDefaultPlan Error: $e');
      return null;
    }
  }

  /// Get user's current plan
  Future<Map<String, dynamic>?> getUserPlan(String userId) async {
    try {
      // Get user's profile with plan_id
      final profile = await _supabase
          .schema('munajat_app')
          .from('profiles')
          .select('plan_id, subscription_tier, subscription_expires_at')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return await getDefaultPlan();

      final planId = profile['plan_id'];
      if (planId == null) return await getDefaultPlan();

      // Check if subscription expired
      final expiresAt = profile['subscription_expires_at'];
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (expiry.isBefore(DateTime.now())) {
          return await getDefaultPlan();
        }
      }

      // Get the plan details
      final plan = await _supabase
          .schema('munajat_app')
          .from('subscription_plans')
          .select()
          .eq('id', planId)
          .maybeSingle();

      return plan ?? await getDefaultPlan();
    } catch (e) {
      debugPrint('GetUserPlan Error: $e');
      return await getDefaultPlan();
    }
  }

  /// Get current user's plan
  Future<Map<String, dynamic>?> getCurrentUserPlan() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return await getDefaultPlan();
    return getUserPlan(user.id);
  }

  /// Check if user can add more shops
  Future<bool> canAddShop() async {
    final plan = await getCurrentUserPlan();
    if (plan == null) return false;

    final maxShops = plan['max_shops'] as int? ?? 1;
    if (maxShops == -1) return true; // Unlimited

    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Count user's current shops
    final shops = await _supabase
        .schema('munajat_app')
        .from('shops')
        .select('id')
        .eq('owner_id', user.id);

    return shops.length < maxShops;
  }

  /// Check if user can add more images to a shop
  Future<bool> canAddImage(String shopId) async {
    final plan = await getCurrentUserPlan();
    if (plan == null) return false;

    final maxImages = plan['max_images_per_shop'] as int? ?? 3;
    if (maxImages == -1) return true; // Unlimited

    // Count current gallery images
    final images = await _supabase
        .schema('munajat_app')
        .from('shop_images')
        .select('id')
        .eq('shop_id', shopId)
        .eq('image_type', 'gallery');

    return images.length < maxImages;
  }

  /// Check if user can add more menu items
  Future<bool> canAddMenuItem(String shopId) async {
    final plan = await getCurrentUserPlan();
    if (plan == null) return false;

    final maxItems = plan['max_menu_items_per_shop'] as int? ?? 10;
    if (maxItems == -1) return true; // Unlimited

    // Count current menu items
    final items = await _supabase
        .schema('munajat_app')
        .from('shop_menu_items')
        .select('id')
        .eq('shop_id', shopId);

    return items.length < maxItems;
  }

  /// Get usage stats for current user
  Future<Map<String, dynamic>> getUsageStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'shops': 0, 'maxShops': 1};
    }

    try {
      final plan = await getCurrentUserPlan();

      final shops = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select('id')
          .eq('owner_id', user.id);

      return {
        'shops': shops.length,
        'maxShops': plan?['max_shops'] ?? 1,
        'maxImages': plan?['max_images_per_shop'] ?? 3,
        'maxMenuItems': plan?['max_menu_items_per_shop'] ?? 10,
        'showBadge': plan?['show_premium_badge'] ?? false,
        'priorityListing': plan?['priority_listing'] ?? false,
      };
    } catch (e) {
      debugPrint('GetUsageStats Error: $e');
      return {'shops': 0, 'maxShops': 1};
    }
  }

  // ============ ADMIN FUNCTIONS ============

  /// Create a new plan
  Future<void> createPlan(Map<String, dynamic> planData) async {
    try {
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .insert(planData);
    } catch (e) {
      debugPrint('CreatePlan Error: $e');
      rethrow;
    }
  }

  /// Update a plan
  Future<void> updatePlan(String planId, Map<String, dynamic> planData) async {
    try {
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .update({...planData, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', planId);
    } catch (e) {
      debugPrint('UpdatePlan Error: $e');
      rethrow;
    }
  }

  /// Toggle plan active status
  Future<void> togglePlanStatus(String planId, bool isActive) async {
    try {
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .update({'is_active': isActive})
          .eq('id', planId);
    } catch (e) {
      debugPrint('TogglePlanStatus Error: $e');
      rethrow;
    }
  }

  /// Set default plan
  Future<void> setDefaultPlan(String planId) async {
    try {
      // Remove default from all plans
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .update({'is_default': false})
          .neq('id', planId);

      // Set new default
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .update({'is_default': true})
          .eq('id', planId);
    } catch (e) {
      debugPrint('SetDefaultPlan Error: $e');
      rethrow;
    }
  }

  /// Assign plan to user
  Future<void> assignPlanToUser(
    String userId,
    String planId, {
    int? durationDays,
  }) async {
    try {
      final plan = await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .select('duration_days')
          .eq('id', planId)
          .single();

      final days = durationDays ?? (plan['duration_days'] as int? ?? 30);
      final expiresAt = DateTime.now().add(Duration(days: days));

      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('profiles')
          .update({
            'plan_id': planId,
            'subscription_expires_at': expiresAt.toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('AssignPlanToUser Error: $e');
      rethrow;
    }
  }

  /// Delete a plan (soft delete by setting inactive)
  Future<void> deletePlan(String planId) async {
    try {
      await AdminSupabaseClient.client
          .schema('munajat_app')
          .from('subscription_plans')
          .update({'is_active': false})
          .eq('id', planId);
    } catch (e) {
      debugPrint('DeletePlan Error: $e');
      rethrow;
    }
  }
}
