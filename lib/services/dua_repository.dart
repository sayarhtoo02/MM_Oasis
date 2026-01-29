import 'dart:convert';
import '../models/dua_model.dart';
import 'database/oasismm_database.dart';

class DuaRepository {
  Future<List<Dua>> loadAllDuas() async {
    final rows = await OasisMMDatabase.getMunajat();
    return rows.map((row) => _duaFromRow(row)).toList();
  }

  Future<List<Dua>> getDuasByManzil(int manzilNumber) async {
    final allDuas = await loadAllDuas();
    return allDuas.where((dua) => dua.manzilNumber == manzilNumber).toList();
  }

  Dua _duaFromRow(Map<String, dynamic> row) {
    // Try to parse from data_json if available (stores full structure)
    if (row['data_json'] != null) {
      try {
        final jsonData = json.decode(row['data_json'] as String);
        return Dua.fromJson(jsonData);
      } catch (_) {
        // Fall through to manual parsing
      }
    }

    // Manual parsing from individual columns
    return Dua(
      id: row['id']?.toString() ?? '',
      manzilNumber: row['manzil_number'] ?? 1,
      day: row['day'] ?? '',
      pageNumber: row['page_number'] ?? 1,
      source: row['source'],
      arabicText: row['arabic_text'] ?? '',
      translations: Translations(
        urdu: row['translation_urdu'] ?? '',
        english: row['translation'] ?? '',
        burmese: row['translation_burmese'] ?? '',
      ),
      faida: Faida(
        urdu: row['faida_urdu'],
        english: row['faida_english'],
        burmese: row['faida_burmese'],
      ),
      audioUrl: row['audio_url'],
      notes: row['notes'],
    );
  }
}
