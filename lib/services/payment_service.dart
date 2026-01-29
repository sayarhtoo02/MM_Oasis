import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';
import 'package:munajat_e_maqbool_app/services/r2_storage_service.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Admin client that bypasses RLS
  final SupabaseClient _adminClient = AdminSupabaseClient.client;
  // R2 Storage for file uploads
  final R2StorageService _r2Storage = R2StorageService();

  // ============ PAYMENT METHODS ============

  /// Get all active payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetPaymentMethods Error: $e');
      return [];
    }
  }

  /// Get all payment methods (for admin) - uses service role
  Future<List<Map<String, dynamic>>> getAllPaymentMethods() async {
    try {
      final response = await _adminClient
          .schema('munajat_app')
          .from('payment_methods')
          .select()
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllPaymentMethods Error: $e');
      return [];
    }
  }

  /// Create payment method (admin) - uses service role
  Future<void> createPaymentMethod(Map<String, dynamic> data) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('payment_methods')
          .insert(data);
    } catch (e) {
      debugPrint('CreatePaymentMethod Error: $e');
      rethrow;
    }
  }

  /// Update payment method (admin) - uses service role
  Future<void> updatePaymentMethod(String id, Map<String, dynamic> data) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('payment_methods')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      debugPrint('UpdatePaymentMethod Error: $e');
      rethrow;
    }
  }

  /// Delete payment method (admin) - uses service role
  Future<void> deletePaymentMethod(String id) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('payment_methods')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('DeletePaymentMethod Error: $e');
      rethrow;
    }
  }

  // ============ SUBSCRIPTION REQUESTS ============

  /// Submit subscription request with screenshot
  Future<void> submitSubscriptionRequest({
    required String planId,
    required String paymentMethodId,
    required File screenshotFile,
    String? transactionId,
    double? amount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Upload screenshot using R2StorageService
      final screenshotUrl = await _r2Storage.uploadFile(
        file: screenshotFile,
        path:
            'payment_screenshots/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create request
      await _supabase
          .schema('munajat_app')
          .from('subscription_requests')
          .insert({
            'user_id': user.id,
            'plan_id': planId,
            'payment_method_id': paymentMethodId,
            'screenshot_url': screenshotUrl,
            'transaction_id': transactionId,
            'amount': amount,
            'status': 'pending',
          });
    } catch (e) {
      debugPrint('SubmitSubscriptionRequest Error: $e');
      rethrow;
    }
  }

  /// Get user's subscription requests
  Future<List<Map<String, dynamic>>> getMyRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('subscription_requests')
          .select('''
            *,
            plan:plan_id (name, price),
            payment_method:payment_method_id (name, provider)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetMyRequests Error: $e');
      return [];
    }
  }

  /// Get all pending requests (admin) - uses service role
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _adminClient
          .schema('munajat_app')
          .from('subscription_requests')
          .select('''
            *,
            plan:plan_id (name, price, duration_days),
            payment_method:payment_method_id (name, provider)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      // Get user profiles separately
      final requests = List<Map<String, dynamic>>.from(response);
      for (var request in requests) {
        final userId = request['user_id'];
        final profile = await _adminClient
            .schema('munajat_app')
            .from('profiles')
            .select('username, email')
            .eq('id', userId)
            .maybeSingle();
        request['user_profile'] = profile;
      }

      return requests;
    } catch (e) {
      debugPrint('GetPendingRequests Error: $e');
      return [];
    }
  }

  /// Get all requests (admin) - uses service role
  Future<List<Map<String, dynamic>>> getAllRequests() async {
    try {
      final response = await _adminClient
          .schema('munajat_app')
          .from('subscription_requests')
          .select('''
            *,
            plan:plan_id (name, price, duration_days),
            payment_method:payment_method_id (name, provider)
          ''')
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllRequests Error: $e');
      return [];
    }
  }

  /// Approve subscription request (admin) - uses service role
  Future<void> approveRequest(String requestId) async {
    try {
      // Get request details
      final request = await _adminClient
          .schema('munajat_app')
          .from('subscription_requests')
          .select('user_id, plan_id, plan:plan_id (duration_days)')
          .eq('id', requestId)
          .single();

      final userId = request['user_id'];
      final planId = request['plan_id'];
      final durationDays = request['plan']?['duration_days'] ?? 30;

      // Update request status
      await _adminClient
          .schema('munajat_app')
          .from('subscription_requests')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Assign plan to user
      final expiresAt = DateTime.now().add(Duration(days: durationDays));
      await _adminClient
          .schema('munajat_app')
          .from('profiles')
          .update({
            'plan_id': planId,
            'subscription_expires_at': expiresAt.toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('ApproveRequest Error: $e');
      rethrow;
    }
  }

  /// Reject subscription request (admin) - uses service role
  Future<void> rejectRequest(String requestId, {String? reason}) async {
    try {
      await _adminClient
          .schema('munajat_app')
          .from('subscription_requests')
          .update({
            'status': 'rejected',
            'admin_notes': reason,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      debugPrint('RejectRequest Error: $e');
      rethrow;
    }
  }
}
