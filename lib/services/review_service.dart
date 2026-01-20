import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all reviews for a shop
  Future<List<Map<String, dynamic>>> getShopReviews(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .select('*, user:profiles(username, avatar_url)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetShopReviews Error: $e');
      return [];
    }
  }

  /// Get average rating for a shop
  Future<double> getShopAverageRating(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .select('rating')
          .eq('shop_id', shopId);

      if (response.isEmpty) return 0;

      final ratings = List<Map<String, dynamic>>.from(response);
      final sum = ratings.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
      return sum / ratings.length;
    } catch (e) {
      debugPrint('GetAverageRating Error: $e');
      return 0;
    }
  }

  /// Get review count for a shop
  Future<int> getReviewCount(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .select('id')
          .eq('shop_id', shopId);
      return response.length;
    } catch (e) {
      debugPrint('GetReviewCount Error: $e');
      return 0;
    }
  }

  /// Check if current user has reviewed a shop
  Future<Map<String, dynamic>?> getUserReview(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .select()
          .eq('shop_id', shopId)
          .eq('user_id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('GetUserReview Error: $e');
      return null;
    }
  }

  /// Create or update a review
  Future<void> submitReview({
    required String shopId,
    required int rating,
    String? comment,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to review');

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    try {
      // Check if user already has a review
      final existing = await getUserReview(shopId);

      if (existing != null) {
        // Update existing review
        await _supabase
            .schema('munajat_app')
            .from('shop_reviews')
            .update({'rating': rating, 'comment': comment})
            .eq('id', existing['id']);
      } else {
        // Create new review
        await _supabase.schema('munajat_app').from('shop_reviews').insert({
          'shop_id': shopId,
          'user_id': user.id,
          'rating': rating,
          'comment': comment,
        });
      }
    } catch (e) {
      debugPrint('SubmitReview Error: $e');
      rethrow;
    }
  }

  /// Delete user's review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .delete()
          .eq('id', reviewId);
    } catch (e) {
      debugPrint('DeleteReview Error: $e');
      rethrow;
    }
  }
}
