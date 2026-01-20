import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  // Use service role client for admin operations (bypasses RLS)
  final SupabaseClient _supabase = AdminSupabaseClient.client;

  // Admin user ID (hardcoded for admin@oasismm.site)
  static const String _adminUserId = '29fb94e1-8d7e-4076-9d23-d3245ec1cce4';

  /// Check if admin is logged in (local check)
  Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('admin_logged_in') ?? false;
  }

  /// Get pending shops for approval
  Future<List<Map<String, dynamic>>> getPendingShops() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetPendingShops Error: $e');
      return [];
    }
  }

  /// Get all shops (for admin view)
  Future<List<Map<String, dynamic>>> getAllShops({String? statusFilter}) async {
    try {
      var query = _supabase.schema('munajat_app').from('shops').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllShops Error: $e');
      return [];
    }
  }

  /// Approve a shop
  Future<void> approveShop(String shopId, {String? notes}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'approved_by': _adminUserId,
            'rejection_reason': null,
          })
          .eq('id', shopId);

      await _logAdminAction(
        actionType: 'approve_shop',
        targetTable: 'shops',
        targetId: shopId,
        notes: notes,
      );
    } catch (e) {
      debugPrint('ApproveShop Error: $e');
      rethrow;
    }
  }

  /// Reject a shop
  Future<void> rejectShop(String shopId, {required String reason}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'rejected', 'rejection_reason': reason})
          .eq('id', shopId);

      await _logAdminAction(
        actionType: 'reject_shop',
        targetTable: 'shops',
        targetId: shopId,
        notes: reason,
      );
    } catch (e) {
      debugPrint('RejectShop Error: $e');
      rethrow;
    }
  }

  /// Suspend a shop
  Future<void> suspendShop(String shopId, {required String reason}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'suspended', 'rejection_reason': reason})
          .eq('id', shopId);

      await _logAdminAction(
        actionType: 'suspend_shop',
        targetTable: 'shops',
        targetId: shopId,
        notes: reason,
      );
    } catch (e) {
      debugPrint('SuspendShop Error: $e');
      rethrow;
    }
  }

  /// Reactivate a suspended shop
  Future<void> reactivateShop(String shopId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shops')
          .update({'status': 'approved', 'rejection_reason': null})
          .eq('id', shopId);

      await _logAdminAction(
        actionType: 'reactivate_shop',
        targetTable: 'shops',
        targetId: shopId,
      );
    } catch (e) {
      debugPrint('ReactivateShop Error: $e');
      rethrow;
    }
  }

  // --- Masjid Management ---

  /// Get pending masjids for approval
  Future<List<Map<String, dynamic>>> getPendingMasjids() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetPendingMasjids Error: $e');
      return [];
    }
  }

  /// Get all masjids (for admin view)
  Future<List<Map<String, dynamic>>> getAllMasjids({
    String? statusFilter,
  }) async {
    try {
      var query = _supabase.schema('munajat_app').from('masjids').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllMasjids Error: $e');
      return [];
    }
  }

  /// Approve a masjid
  Future<void> approveMasjid(String masjidId, {String? notes}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'approved_by': _adminUserId,
            'rejection_reason': null,
          })
          .eq('id', masjidId);

      await _logAdminAction(
        actionType: 'approve_masjid',
        targetTable: 'masjids',
        targetId: masjidId,
        notes: notes,
      );
    } catch (e) {
      debugPrint('ApproveMasjid Error: $e');
      rethrow;
    }
  }

  /// Reject a masjid
  Future<void> rejectMasjid(String masjidId, {required String reason}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({'status': 'rejected', 'rejection_reason': reason})
          .eq('id', masjidId);

      await _logAdminAction(
        actionType: 'reject_masjid',
        targetTable: 'masjids',
        targetId: masjidId,
        notes: reason,
      );
    } catch (e) {
      debugPrint('RejectMasjid Error: $e');
      rethrow;
    }
  }

  /// Suspend a masjid
  Future<void> suspendMasjid(String masjidId, {required String reason}) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({'status': 'suspended', 'rejection_reason': reason})
          .eq('id', masjidId);

      await _logAdminAction(
        actionType: 'suspend_masjid',
        targetTable: 'masjids',
        targetId: masjidId,
        notes: reason,
      );
    } catch (e) {
      debugPrint('SuspendMasjid Error: $e');
      rethrow;
    }
  }

  /// Reactivate a suspended masjid
  Future<void> reactivateMasjid(String masjidId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({'status': 'approved', 'rejection_reason': null})
          .eq('id', masjidId);

      await _logAdminAction(
        actionType: 'reactivate_masjid',
        targetTable: 'masjids',
        targetId: masjidId,
      );
    } catch (e) {
      debugPrint('ReactivateMasjid Error: $e');
      rethrow;
    }
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAllUsers Error: $e');
      return [];
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('profiles')
          .update({'role': role})
          .eq('id', userId);

      await _logAdminAction(
        actionType: 'update_user_role',
        targetTable: 'profiles',
        targetId: userId,
        notes: 'Changed role to: $role',
      );
    } catch (e) {
      debugPrint('UpdateUserRole Error: $e');
      rethrow;
    }
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final shops = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select('status');

      final users = await _supabase
          .schema('munajat_app')
          .from('profiles')
          .select('id');

      final reviews = await _supabase
          .schema('munajat_app')
          .from('shop_reviews')
          .select('id');

      final masjids = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .select('status');

      final shopList = List<Map<String, dynamic>>.from(shops);
      final masjidList = List<Map<String, dynamic>>.from(masjids);

      return {
        'totalShops': shopList.length,
        'pendingShops': shopList.where((s) => s['status'] == 'pending').length,
        'approvedShops': shopList
            .where((s) => s['status'] == 'approved')
            .length,
        'rejectedShops': shopList
            .where((s) => s['status'] == 'rejected')
            .length,
        'suspendedShops': shopList
            .where((s) => s['status'] == 'suspended')
            .length,
        'totalUsers': users.length,
        'totalReviews': reviews.length,
        'totalMasjids': masjidList.length,
        'pendingMasjids': masjidList
            .where((m) => m['status'] == 'pending')
            .length,
        'approvedMasjids': masjidList
            .where((m) => m['status'] == 'approved')
            .length,
        'rejectedMasjids': masjidList
            .where((m) => m['status'] == 'rejected')
            .length,
        'suspendedMasjids': masjidList
            .where((m) => m['status'] == 'suspended')
            .length,
      };
    } catch (e) {
      debugPrint('GetDashboardStats Error: $e');
      return {};
    }
  }

  /// Get admin action logs
  Future<List<Map<String, dynamic>>> getAdminLogs({int limit = 50}) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('admin_actions')
          .select('*, admin:profiles(username)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetAdminLogs Error: $e');
      return [];
    }
  }

  /// Log an admin action
  Future<void> _logAdminAction({
    required String actionType,
    required String targetTable,
    required String targetId,
    String? notes,
  }) async {
    try {
      await _supabase.schema('munajat_app').from('admin_actions').insert({
        'admin_id': _adminUserId,
        'action_type': actionType,
        'target_table': targetTable,
        'target_id': targetId,
        'notes': notes,
      });
    } catch (e) {
      debugPrint('LogAdminAction Error: $e');
    }
  }
}
