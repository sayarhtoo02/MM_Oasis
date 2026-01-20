import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasjidService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all approved masjids
  Future<List<Map<String, dynamic>>> getMasjids() async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetMasjids Error: $e');
      rethrow;
    }
  }

  /// Fetch a single masjid with its jamat times and images
  Future<Map<String, dynamic>?> getMasjidDetails(String id) async {
    try {
      final masjidResponse = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (masjidResponse == null) return null;

      final jamatResponse = await _supabase
          .schema('munajat_app')
          .from('masjid_jamat_times')
          .select()
          .eq('masjid_id', id)
          .maybeSingle();

      final imagesResponse = await _supabase
          .schema('munajat_app')
          .from('masjid_images')
          .select()
          .eq('masjid_id', id)
          .order('display_order', ascending: true);

      final data = Map<String, dynamic>.from(masjidResponse);
      data['jamat_times'] = jamatResponse;
      data['images'] = imagesResponse;

      return data;
    } catch (e) {
      debugPrint('GetMasjidDetails Error: $e');
      return null;
    }
  }

  /// Register a new masjid (pending approval)
  Future<String?> registerMasjid(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final masjidData = {...data, 'manager_id': user.id, 'status': 'pending'};

      final response = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .insert(masjidData)
          .select('id')
          .single();

      final masjidId = response['id'] as String;

      // Initialize jamat times
      await _supabase.schema('munajat_app').from('masjid_jamat_times').insert({
        'masjid_id': masjidId,
      });

      return masjidId;
    } catch (e) {
      debugPrint('RegisterMasjid Error: $e');
      rethrow;
    }
  }

  /// Fetch masjids managed by the current user
  Future<List<Map<String, dynamic>>> getMyMasjids() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .schema('munajat_app')
          .from('masjids')
          .select()
          .eq('manager_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetMyMasjids Error: $e');
      return [];
    }
  }
}
