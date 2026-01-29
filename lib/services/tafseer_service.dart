import 'database/oasismm_database.dart';

class TafseerService {
  /// Load Myanmar Tafseer for specific ayah
  static Future<List<TafseerItem>> getMyanmarTafseer(String ayahKey) async {
    try {
      final parts = ayahKey.split(':');
      if (parts.length != 2) return [];

      final surahId = int.tryParse(parts[0]) ?? 0;
      final ayahNumber = int.tryParse(parts[1]) ?? 0;

      final results = await OasisMMDatabase.getTafseer(
        surahId,
        ayahNumber,
        'mm',
      );

      return results
          .map(
            (row) => TafseerItem(
              ayahKey: ayahKey,
              groupAyahKey:
                  '${row['surah_id']}:${row['verse_start']}-${row['verse_end'] ?? row['verse_start']}',
              fromAyah: '${row['surah_id']}:${row['verse_start']}',
              toAyah:
                  '${row['surah_id']}:${row['verse_end'] ?? row['verse_start']}',
              ayahKeys: '',
              text: row['text'] ?? '',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load English Tafseer for specific ayah
  static Future<List<TafseerItem>> getEnglishTafseer(String ayahKey) async {
    try {
      final parts = ayahKey.split(':');
      if (parts.length != 2) return [];

      final surahId = int.tryParse(parts[0]) ?? 0;
      final ayahNumber = int.tryParse(parts[1]) ?? 0;

      final results = await OasisMMDatabase.getTafseer(
        surahId,
        ayahNumber,
        'en',
      );

      return results
          .map(
            (row) => TafseerItem(
              ayahKey: ayahKey,
              groupAyahKey:
                  '${row['surah_id']}:${row['verse_start']}-${row['verse_end'] ?? row['verse_start']}',
              fromAyah: '${row['surah_id']}:${row['verse_start']}',
              toAyah:
                  '${row['surah_id']}:${row['verse_end'] ?? row['verse_start']}',
              ayahKeys: '',
              text: row['text'] ?? '',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class TafseerItem {
  final String ayahKey;
  final String groupAyahKey;
  final String fromAyah;
  final String toAyah;
  final String ayahKeys;
  final String text;

  TafseerItem({
    required this.ayahKey,
    required this.groupAyahKey,
    required this.fromAyah,
    required this.toAyah,
    required this.ayahKeys,
    required this.text,
  });

  factory TafseerItem.fromJson(Map<String, dynamic> json) {
    return TafseerItem(
      ayahKey: json['ayah_key'] ?? '',
      groupAyahKey: json['group_ayah_key'] ?? '',
      fromAyah: json['from_ayah'] ?? '',
      toAyah: json['to_ayah'] ?? '',
      ayahKeys: json['ayah_keys'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
