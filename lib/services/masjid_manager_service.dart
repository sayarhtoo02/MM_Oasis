import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasjidManagerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update Jamat times for a masjid
  Future<void> updateJamatTimes(
    String masjidId,
    Map<String, String> times,
  ) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjid_jamat_times')
          .update({...times, 'updated_at': DateTime.now().toIso8601String()})
          .eq('masjid_id', masjidId);
    } catch (e) {
      debugPrint('Update Jamat Times Error: $e');
      rethrow;
    }
  }

  /// Update Masjid basic info (Description, Facilities, Bayan Languages)
  Future<void> updateMasjidInfo(
    String masjidId,
    Map<String, dynamic> info,
  ) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update(info)
          .eq('id', masjidId);
    } catch (e) {
      debugPrint('Update Masjid Info Error: $e');
      rethrow;
    }
  }

  /// Update Masjid facilities
  Future<void> updateFacilities(
    String masjidId,
    Map<String, bool> facilities,
  ) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({'facilities': facilities})
          .eq('id', masjidId);
    } catch (e) {
      debugPrint('Update Facilities Error: $e');
      rethrow;
    }
  }

  /// Update Bayan languages
  Future<void> updateBayanLanguages(
    String masjidId,
    List<String> languages,
  ) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('masjids')
          .update({'bayan_languages': languages})
          .eq('id', masjidId);
    } catch (e) {
      debugPrint('Update Bayan Languages Error: $e');
      rethrow;
    }
  }
}
