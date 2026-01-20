import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';

class AdsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Admin client that bypasses RLS
  final SupabaseClient _adminClient = AdminSupabaseClient.client;

  /// Get active ads banners for display
  Future<List<Map<String, dynamic>>> getActiveAds() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('ads_banners')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false)
          .limit(5);

      // Filter by date in Dart for more reliable results
      final now = DateTime.now();
      final filteredAds = List<Map<String, dynamic>>.from(response).where((ad) {
        final startDate = ad['start_date'] != null
            ? DateTime.parse(ad['start_date'])
            : null;
        final endDate = ad['end_date'] != null
            ? DateTime.parse(ad['end_date'])
            : null;

        if (startDate != null && now.isBefore(startDate)) return false;
        if (endDate != null && now.isAfter(endDate)) return false;
        return true;
      }).toList();

      return filteredAds;
    } catch (e) {
      debugPrint('GetActiveAds Error: $e');
      return [];
    }
  }

  /// Get all ads (for admin) - uses service role to bypass RLS
  Future<List<Map<String, dynamic>>> getAllAds() async {
    try {
      final response = await _adminClient
          .schema('munajat_app')
          .from('ads_banners')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllAds Error: $e');
      return [];
    }
  }

  /// Record ad view
  Future<void> recordView(String adId) async {
    try {
      await _supabase.rpc('increment_ad_view', params: {'ad_id': adId});
    } catch (e) {
      // Silently fail - just increment counter
      debugPrint('RecordView Error: $e');
    }
  }

  /// Record ad click
  Future<void> recordClick(String adId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('ads_banners')
          .update({'click_count': _supabase.rpc('increment')})
          .eq('id', adId);
    } catch (e) {
      debugPrint('RecordClick Error: $e');
    }
  }

  // ============ ADMIN FUNCTIONS (using service role) ============

  /// Create a new ad - uses service role to bypass RLS
  Future<void> createAd(Map<String, dynamic> adData) async {
    try {
      await _adminClient.schema('munajat_app').from('ads_banners').insert({
        ...adData,
      });
    } catch (e) {
      debugPrint('CreateAd Error: $e');
      rethrow;
    }
  }

  /// Update an ad - uses service role to bypass RLS
  Future<void> updateAd(String adId, Map<String, dynamic> adData) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('ads_banners')
          .update({...adData, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', adId);
    } catch (e) {
      debugPrint('UpdateAd Error: $e');
      rethrow;
    }
  }

  /// Toggle ad active status - uses service role to bypass RLS
  Future<void> toggleAdStatus(String adId, bool isActive) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('ads_banners')
          .update({'is_active': isActive})
          .eq('id', adId);
    } catch (e) {
      debugPrint('ToggleAdStatus Error: $e');
      rethrow;
    }
  }

  /// Delete an ad - uses service role to bypass RLS
  Future<void> deleteAd(String adId) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('ads_banners')
          .delete()
          .eq('id', adId);
    } catch (e) {
      debugPrint('DeleteAd Error: $e');
      rethrow;
    }
  }

  /// Get ad statistics - uses service role to bypass RLS
  Future<Map<String, dynamic>> getAdStats(String adId) async {
    try {
      final ad = await _adminClient
          .schema('munajat_app')
          .from('ads_banners')
          .select('view_count, click_count')
          .eq('id', adId)
          .single();

      final views = ad['view_count'] as int? ?? 0;
      final clicks = ad['click_count'] as int? ?? 0;
      final ctr = views > 0 ? (clicks / views * 100) : 0.0;

      return {'views': views, 'clicks': clicks, 'ctr': ctr.toStringAsFixed(2)};
    } catch (e) {
      debugPrint('GetAdStats Error: $e');
      return {'views': 0, 'clicks': 0, 'ctr': '0.00'};
    }
  }

  /// Submit a promotion request (for shop owners)
  Future<void> requestPromotion({
    required String shopId,
    required String adTitle,
    required String adDescription,
    required String bannerUrl,
    String? targetType,
    String? targetId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // For now, we insert into ads_banners with is_active = false
      // This serves as a "pending" ad request for the admin to review
      await _supabase.schema('munajat_app').from('ads_banners').insert({
        'title': adTitle,
        'description': adDescription,
        'image_url': bannerUrl,
        'target_type': targetType ?? 'shop',
        'target_id': targetId ?? shopId,
        'is_active': false,
        'priority': 0,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('RequestPromotion Error: $e');
      rethrow;
    }
  }
}
