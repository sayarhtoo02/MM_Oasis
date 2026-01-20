import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quran_surah.dart';
import '../models/quran_ayah.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show LineSplitter, json;
import 'package:flutter/foundation.dart' show debugPrint;

class QuranService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran_cache.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE surahs(
            number INTEGER PRIMARY KEY,
            name_arabic TEXT,
            name_simple TEXT,
            englishNameTranslation TEXT,
            verses_count INTEGER,
            revelation_place TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE ayahs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            number INTEGER,
            text TEXT,
            numberInSurah INTEGER,
            juz INTEGER,
            manzil INTEGER,
            page INTEGER,
            ruku INTEGER,
            hizbQuarter INTEGER,
            FOREIGN KEY (surah_number) REFERENCES surahs(number)
          )
        ''');

        await db.execute('''
          CREATE TABLE translations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            ayah_number INTEGER,
            language TEXT,
            text TEXT,
            UNIQUE(surah_number, ayah_number, language)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.delete('surahs');
          await db.delete('ayahs');
          await db.delete('translations');
        }
      },
    );
  }

  Future<List<QuranSurah>> getAllSurahs() async {
    final db = await database;
    final cached = await db.query('surahs', orderBy: 'number ASC');

    if (cached.isNotEmpty) {
      return cached.map((json) => QuranSurah.fromJson(json)).toList();
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/chapters'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chapters = data['chapters'] as List;
        final surahs = chapters
            .map((json) => QuranSurah.fromApi(json))
            .toList();

        for (var surah in surahs) {
          await db.insert(
            'surahs',
            surah.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        return surahs;
      }
    } catch (e) {
      // Ignore error
    }

    return [];
  }

  Future<Map<String, dynamic>> getSurahWithTranslation(
    int surahNumber,
    String language,
  ) async {
    final db = await database;

    final surahData = await db.query(
      'surahs',
      where: 'number = ?',
      whereArgs: [surahNumber],
    );

    if (surahData.isEmpty) {
      await getAllSurahs();
      // Recursive call might be dangerous if getAllSurahs fails, but keeping existing logic structure
      final retryData = await db.query(
        'surahs',
        where: 'number = ?',
        whereArgs: [surahNumber],
      );
      if (retryData.isEmpty) return {};
    }

    // Re-query surah data to be safe or use existing if found
    final surah = QuranSurah.fromJson(
      surahData.isNotEmpty
          ? surahData.first
          : (await db.query(
              'surahs',
              where: 'number = ?',
              whereArgs: [surahNumber],
            )).first,
    );

    final ayahsData = await db.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'numberInSurah ASC',
    );

    List<QuranAyah> ayahs;

    if (ayahsData.isEmpty) {
      ayahs = await _fetchAndCacheAyahs(surahNumber);
    } else {
      ayahs = ayahsData.map((json) => QuranAyah.fromJson(json)).toList();
    }

    // Fetch translations if needed
    if (language == 'burmese') {
      final translationsData = await db.query(
        'translations',
        where: 'surah_number = ? AND language = ?',
        whereArgs: [surahNumber, language],
      );

      final translationMap = {
        for (var t in translationsData)
          t['ayah_number'] as int: t['text'] as String,
      };

      ayahs = ayahs.map((ayah) {
        return ayah.copyWith(translation: translationMap[ayah.numberInSurah]);
      }).toList();
    }

    return {'surah': surah, 'ayahs': ayahs};
  }

  Future<List<QuranAyah>> _fetchAndCacheAyahs(int surahNumber) async {
    try {
      final allAyahs = <QuranAyah>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final url =
            '$_baseUrl/verses/by_chapter/$surahNumber?language=en&words=false&page=$page&per_page=50';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final verses = data['verses'] as List;

          if (verses.isEmpty) {
            hasMore = false;
            break;
          }

          final ayahs = verses.map((verse) {
            if (verses.indexOf(verse) == 0) {}
            return QuranAyah(
              number: verse['id'] ?? 0,
              text: verse['text_uthmani'] ?? '',
              numberInSurah:
                  verse['verse_key']?.toString().split(':')[1] != null
                  ? int.parse(verse['verse_key'].toString().split(':')[1])
                  : verse['verse_number'] ?? 0,
              juz: verse['juz_number'] ?? 0,
              manzil: verse['manzil_number'] ?? 0,
              page: verse['page_number'] ?? 0,
              ruku: verse['ruku_number'] ?? 0,
              hizbQuarter: verse['hizb_number'] ?? 0,
            );
          }).toList();

          allAyahs.addAll(ayahs);

          final pagination = data['pagination'];
          hasMore = pagination != null && pagination['next_page'] != null;
          page++;
        } else {
          hasMore = false;
        }
      }

      final db = await database;
      final batch = db.batch();

      for (var ayah in allAyahs) {
        batch.insert('ayahs', {
          'surah_number': surahNumber,
          ...ayah.toJson(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      return allAyahs;
    } catch (e) {
      // Ignore error
    }

    return [];
  }

  Future<bool> isQuranDownloaded() async {
    final db = await database;
    final ayahCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    return ayahCount != null && ayahCount > 6000;
  }

  Future<void> downloadCompleteQuran(
    String language,
    Function(int current, int total, String status) onProgress,
  ) async {
    try {
      onProgress(0, 114, 'Fetching Surahs...');
      final surahs = await getAllSurahs();

      int completed = 0;
      const batchSize = 5;

      for (int i = 0; i < surahs.length; i += batchSize) {
        final batch = surahs.skip(i).take(batchSize).toList();

        await Future.wait(
          batch.map((surah) async {
            await _fetchAndCacheAyahs(surah.number);
            completed++;
            onProgress(completed, 114, 'Downloaded ${surah.englishName}');
          }),
        );
      }

      onProgress(114, 114, 'Download Complete!');
    } catch (e) {
      throw Exception('Failed to download Quran: $e');
    }
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('surahs');
    await db.delete('ayahs');
    await db.delete('translations');
  }

  Future<void> importBurmeseTranslation() async {
    try {
      final db = await database;

      // Check if we already have Burmese translations
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM translations WHERE language = 'burmese'",
        ),
      );

      if (count != null && count > 6000) {
        return; // Already imported
      }

      // Load the text file
      final String content = await rootBundle.loadString(
        'assets/quran_data/mya-basein.txt',
      );
      final List<String> lines = LineSplitter.split(content).toList();

      final batch = db.batch();

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split('|');
        if (parts.length >= 3) {
          try {
            final surahNum = int.parse(parts[0].trim());
            final ayahNum = int.parse(parts[1].trim());
            final text = parts
                .sublist(2)
                .join('|')
                .trim(); // Join remaining parts in case text contains pipes

            batch.insert('translations', {
              'surah_number': surahNum,
              'ayah_number': ayahNum,
              'language': 'burmese',
              'text': text,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (e) {
            debugPrint('Error parsing line: $line - $e');
          }
        }
      }

      await batch.commit(noResult: true);
      debugPrint('Burmese translation imported successfully');
    } catch (e) {
      debugPrint('Error importing Burmese translation: $e');
    }
  }
}
