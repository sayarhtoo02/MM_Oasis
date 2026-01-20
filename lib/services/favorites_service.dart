import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's favorite shops
  Future<List<String>> getUserFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('user_favorites')
          .select('shop_id')
          .eq('user_id', user.id);

      return List<String>.from(response.map((r) => r['shop_id'] as String));
    } catch (e) {
      debugPrint('GetUserFavorites Error: $e');
      return [];
    }
  }

  /// Get user's favorite shops with details
  Future<List<Map<String, dynamic>>> getFavoriteShops() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('user_favorites')
          .select('''
            shop_id,
            shops:shop_id (
              id, name, description, address, phone,
              latitude, longitude, category, status,
              cover_image_url, logo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response
          .where((r) => r['shops'] != null)
          .map((r) => r['shops'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('GetFavoriteShops Error: $e');
      return [];
    }
  }

  /// Check if a shop is favorited
  Future<bool> isFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('shop_id', shopId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('IsFavorite Error: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final existing = await _supabase
          .schema('munajat_app')
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('shop_id', shopId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await _supabase
            .schema('munajat_app')
            .from('user_favorites')
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        // Add favorite
        await _supabase.schema('munajat_app').from('user_favorites').insert({
          'user_id': user.id,
          'shop_id': shopId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('ToggleFavorite Error: $e');
      rethrow;
    }
  }

  /// Add to favorites
  Future<void> addFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.schema('munajat_app').from('user_favorites').upsert({
        'user_id': user.id,
        'shop_id': shopId,
      });
    } catch (e) {
      debugPrint('AddFavorite Error: $e');
      rethrow;
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .schema('munajat_app')
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('shop_id', shopId);
    } catch (e) {
      debugPrint('RemoveFavorite Error: $e');
      rethrow;
    }
  }
}
