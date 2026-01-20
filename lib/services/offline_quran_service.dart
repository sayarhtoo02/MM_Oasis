import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quran_surah.dart';
import '../models/quran_ayah.dart';

class OfflineQuranService {
  List<QuranSurah>? _cachedSurahs;
  final Map<int, List<QuranAyah>> _cachedAyahs = {};
  final Map<String, Map<String, String>> _allTranslations = {};
  Database? _quranDatabase;

  Future<Database> get quranDatabase async {
    if (_quranDatabase != null) return _quranDatabase!;
    _quranDatabase = await _initQuranDatabase();
    return _quranDatabase!;
  }

  Future<Database> _initQuranDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'indopak_nastaleeq_quran.db');

    // Always delete and recopy to ensure we have latest version
    final exists = await databaseExists(path);
    if (exists) {
      debugPrint('Deleting existing Quran database to update...');
      await deleteDatabase(path);
    }

    debugPrint('Copying Quran database from asset...');
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    ByteData data = await rootBundle.load(
      'assets/quran_data/quran_scripts/indopak-nastaleeq.db',
    );
    List<int> bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(path).writeAsBytes(bytes, flush: true);
    debugPrint('Quran database copied to $path');

    final db = await openDatabase(path, readOnly: true);

    // Debug: Check table structure
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('Quran DB tables: $tables');

    if (tables.isNotEmpty) {
      final wordCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM words'),
      );
      debugPrint('Total words in database: $wordCount');
    }

    return db;
  }

  Future<List<QuranSurah>> getAllSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final jsonString = await rootBundle.loadString(
      'assets/quran_data/quran-metadata-surah-name.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);

    _cachedSurahs = data.entries.map((entry) {
      final surahData = entry.value as Map<String, dynamic>;
      return QuranSurah(
        number: surahData['id'],
        name: surahData['name_arabic'],
        englishName: surahData['name_simple'],
        englishNameTranslation: surahData['name'],
        numberOfAyahs: surahData['verses_count'],
        revelationType: surahData['revelation_place'],
      );
    }).toList();

    return _cachedSurahs!;
  }

  Future<Map<String, String>> _loadTranslationFile(String fileName) async {
    final text = await rootBundle.loadString('assets/quran_data/$fileName');
    final lines = text.split('\n');

    final translations = <String, String>{};
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 3) {
        final key = '${parts[0]}_${parts[1]}';
        translations[key] = parts[2];
      }
    }

    return translations;
  }

  Future<void> _loadAllTranslations() async {
    if (_allTranslations.isNotEmpty) return;

    _allTranslations['basein'] = await _loadTranslationFile('mya-basein.txt');
    _allTranslations['ghazimohammadha'] = await _loadTranslationFile(
      'mya-ghazimohammadha.txt',
    );
    _allTranslations['hashimtinmyint'] = await _loadTranslationFile(
      'mya-hashimtinmyint.txt',
    );
  }

  /// Get Arabic text for an ayah from the indopak-nastaleeq database
  Future<String> _getArabicText(int surahNumber, int ayahNumber) async {
    final db = await quranDatabase;

    // Query all words for this ayah and join them
    final wordMaps = await db.query(
      'words',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surahNumber, ayahNumber],
      orderBy: 'word_position ASC',
    );

    if (wordMaps.isEmpty) {
      return '';
    }

    // Join all word texts with spaces
    return wordMaps.map((w) => w['text'] as String).join(' ');
  }

  /// Get all Arabic texts for a surah from the database
  Future<Map<int, String>> _getArabicTextsForSurah(int surahNumber) async {
    final db = await quranDatabase;

    // Get all words for this surah - column is 'word' not 'word_position'
    final wordMaps = await db.query(
      'words',
      where: 'surah = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah ASC, word ASC',
    );

    // Group words by ayah
    final ayahTexts = <int, List<String>>{};
    for (var word in wordMaps) {
      final ayah = word['ayah'] as int;
      final text = word['text'] as String;
      ayahTexts.putIfAbsent(ayah, () => []);
      ayahTexts[ayah]!.add(text);
    }

    // Join words for each ayah
    return ayahTexts.map((ayah, words) => MapEntry(ayah, words.join(' ')));
  }

  Future<Map<String, dynamic>> getSurahWithAyahs(int surahNumber) async {
    if (_cachedAyahs.containsKey(surahNumber)) {
      final surahs = await getAllSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      return {'surah': surah, 'ayahs': _cachedAyahs[surahNumber]};
    }

    // Load translations
    await _loadAllTranslations();

    // Get surah metadata
    final surahs = await getAllSurahs();
    final surah = surahs.firstWhere((s) => s.number == surahNumber);

    // Get Arabic texts from database
    final arabicTexts = await _getArabicTextsForSurah(surahNumber);

    // Build ayahs list
    final ayahs = <QuranAyah>[];
    for (int ayahNumber = 1; ayahNumber <= surah.numberOfAyahs; ayahNumber++) {
      final translationKey = '${surahNumber}_$ayahNumber';

      final ayahTranslations = <String, String>{};
      for (var translationName in _allTranslations.keys) {
        final translation = _allTranslations[translationName]![translationKey];
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

    await _loadAllTranslations();
    final translations = _allTranslations[translationKey];
    if (translations == null) return [];

    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    for (var entry in translations.entries) {
      if (entry.value.toLowerCase().contains(lowerQuery)) {
        final parts = entry.key.split('_');
        if (parts.length == 2) {
          results.add({
            'surah': int.tryParse(parts[0]) ?? 0,
            'ayah': int.tryParse(parts[1]) ?? 0,
            'text': entry.value,
          });
        }
      }
    }

    // Sort results by Surah and Ayah
    results.sort((a, b) {
      final surahComp = (a['surah'] as int).compareTo(b['surah'] as int);
      if (surahComp != 0) return surahComp;
      return (a['ayah'] as int).compareTo(b['ayah'] as int);
    });

    return results;
  }

  // Surah Info
  Map<String, dynamic>? _surahInfo;

  Future<void> _loadSurahInfo() async {
    if (_surahInfo != null) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/quran_data/suran-info-mm.json',
      );
      _surahInfo = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading surah info: $e');
      _surahInfo = {};
    }
  }

  Future<Map<String, dynamic>?> getSurahInfo(int surahNumber) async {
    await _loadSurahInfo();
    return _surahInfo?[surahNumber.toString()];
  }

  void clearCache() {
    _cachedSurahs = null;
    _cachedAyahs.clear();
    _allTranslations.clear();
  }
}
