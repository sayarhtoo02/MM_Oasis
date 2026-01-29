import '../models/quran_surah.dart';
import '../models/quran_ayah.dart';
import 'database/oasismm_database.dart';

class OfflineQuranService {
  List<QuranSurah>? _cachedSurahs;
  final Map<int, List<QuranAyah>> _cachedAyahs = {};

  Future<List<QuranSurah>> getAllSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    // Use consolidated database for surah list
    final surahRows = await OasisMMDatabase.getSurahs();

    _cachedSurahs = surahRows
        .map(
          (row) => QuranSurah(
            number: row['id'] as int,
            name: row['name'] ?? '',
            englishName: row['name_transliteration'] ?? '',
            englishNameTranslation: row['name_transliteration'] ?? '',
            numberOfAyahs: row['total_verses'] ?? 0,
            revelationType: row['revelation_type'] ?? '',
          ),
        )
        .toList();

    return _cachedSurahs!;
  }

  /// Get Arabic texts for a surah from IndoPak words table
  Future<Map<int, String>> _getArabicTextsForSurah(int surahNumber) async {
    final wordRows = await OasisMMDatabase.getIndopakWords(surahNumber);

    final ayahTexts = <int, List<String>>{};
    for (var word in wordRows) {
      final ayah = word['ayah'] as int;
      final text = word['text'] as String? ?? '';
      ayahTexts.putIfAbsent(ayah, () => []);
      ayahTexts[ayah]!.add(text);
    }

    return ayahTexts.map((ayah, words) => MapEntry(ayah, words.join(' ')));
  }

  Future<Map<String, dynamic>> getSurahWithAyahs(int surahNumber) async {
    if (_cachedAyahs.containsKey(surahNumber)) {
      final surahs = await getAllSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      return {'surah': surah, 'ayahs': _cachedAyahs[surahNumber]};
    }

    // Get surah metadata
    final surahs = await getAllSurahs();
    final surah = surahs.firstWhere((s) => s.number == surahNumber);

    // Get Arabic texts from IndoPak words table
    final arabicTexts = await _getArabicTextsForSurah(surahNumber);

    // Get translations from consolidated database
    final translations = <String, Map<String, String>>{};
    for (final translatorKey in ['mya-basein', 'mya-ghazi', 'mya-hashim']) {
      final transRows = await OasisMMDatabase.getTranslations(
        surahNumber,
        translatorKey,
      );
      for (final row in transRows) {
        final ayahNum = row['verse_number'] as int;
        final key = '${surahNumber}_$ayahNum';
        translations.putIfAbsent(
          translatorKey.replaceAll('mya-', ''),
          () => {},
        );
        translations[translatorKey.replaceAll('mya-', '')]![key] =
            row['text'] ?? '';
      }
    }

    // Build ayahs list
    final ayahs = <QuranAyah>[];
    for (int ayahNumber = 1; ayahNumber <= surah.numberOfAyahs; ayahNumber++) {
      final translationKey = '${surahNumber}_$ayahNumber';

      final ayahTranslations = <String, String>{};
      for (var translationName in translations.keys) {
        final translation = translations[translationName]![translationKey];
        if (translation != null) {
          ayahTranslations[translationName] = translation;
        }
      }

      ayahs.add(
        QuranAyah(
          number: ayahNumber,
          text: arabicTexts[ayahNumber] ?? '',
          numberInSurah: ayahNumber,
          juz: 0,
          manzil: 0,
          page: 0,
          ruku: 0,
          hizbQuarter: 0,
          translations: ayahTranslations,
        ),
      );
    }

    _cachedAyahs[surahNumber] = ayahs;

    return {'surah': surah, 'ayahs': ayahs};
  }

  Future<QuranAyah?> getAyah(int surahNumber, int ayahNumber) async {
    final data = await getSurahWithAyahs(surahNumber);
    final ayahs = data['ayahs'] as List<QuranAyah>;
    try {
      return ayahs.firstWhere((a) => a.numberInSurah == ayahNumber);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchAyahs(
    String query,
    String translationKey,
  ) async {
    if (query.trim().isEmpty) return [];

    // Use FTS search from consolidated database
    final db = await OasisMMDatabase.database;

    // Clean query and add wildcard for prefix matching
    final cleanQuery = query.replaceAll('"', '""').trim();
    final ftsQuery = '$cleanQuery*';

    final results = await db.rawQuery(
      '''
      SELECT t.surah_id, t.verse_number, t.text 
      FROM translations t
      JOIN translations_fts f ON t.id = f.rowid
      WHERE t.translator_key = ? AND f.text MATCH ?
      ORDER BY t.surah_id, t.verse_number
      LIMIT 100
    ''',
      ['mya-$translationKey', ftsQuery],
    );

    return results
        .map(
          (row) => {
            'surah': row['surah_id'],
            'ayah': row['verse_number'],
            'text': row['text'],
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>?> getSurahInfo(int surahNumber) async {
    // Use consolidated database
    final info = await OasisMMDatabase.getSurahInfo(surahNumber, 'mm');
    if (info == null) return null;

    return {'text': info['content'], 'surah_id': surahNumber};
  }

  void clearCache() {
    _cachedSurahs = null;
    _cachedAyahs.clear();
  }
}
