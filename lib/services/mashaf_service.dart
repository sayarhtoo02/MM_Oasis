import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mashaf_models.dart';
import 'tajweed/tajweed_data_provider.dart';

class MashafService {
  static Database? _layoutDatabase;
  static Database? _wordsDatabase;

  /// Layout database for pages and info
  Future<Database> get layoutDatabase async {
    if (_layoutDatabase != null) return _layoutDatabase!;
    _layoutDatabase = await _initLayoutDatabase();
    return _layoutDatabase!;
  }

  /// Words database for Quran text
  Future<Database> get wordsDatabase async {
    if (_wordsDatabase != null) return _wordsDatabase!;
    _wordsDatabase = await _initWordsDatabase();
    return _wordsDatabase!;
  }

  Future<Database> _initLayoutDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qudratullah_layout.db');

    final exists = await databaseExists(path);

    if (!exists) {
      debugPrint('Copying layout database from asset...');
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(
        'assets/quran_data/mushaf_layout_data/qudratullah-indopak-15-lines.db',
      );
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('Layout database copied to $path');
    } else {
      debugPrint('Opening existing layout database at $path');
    }

    var db = await openDatabase(path, readOnly: true);

    // Verify tables exist
    var tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='info'",
    );
    if (tables.isEmpty) {
      debugPrint('Layout DB corrupted. Re-copying...');
      await db.close();
      await deleteDatabase(path);
      ByteData data = await rootBundle.load(
        'assets/quran_data/mushaf_layout_data/qudratullah-indopak-15-lines.db',
      );
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      db = await openDatabase(path, readOnly: true);
    }

    var allTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('Layout DB Tables: $allTables');

    return db;
  }

  Future<Database> _initWordsDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'indopak_nastaleeq_words.db');

    // Always delete and recopy to ensure we have latest version with Tajweed data
    final exists = await databaseExists(path);
    if (exists) {
      debugPrint(
        'Deleting existing words database to update with Tajweed data...',
      );
      await deleteDatabase(path);
    }

    debugPrint('Copying words database from asset...');
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
    debugPrint('Words database copied to $path');

    var db = await openDatabase(path, readOnly: true);

    var allTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('Words DB Tables: $allTables');

    // Initialize Tajweed Data Provider
    debugPrint('Initializing Tajweed Data Provider...');
    await TajweedDataProvider().load();

    return db;
  }

  Future<MashafInfo?> getMashafInfo() async {
    try {
      final db = await layoutDatabase;
      final List<Map<String, dynamic>> maps = await db.query('info');
      if (maps.isNotEmpty) {
        return MashafInfo.fromMap(maps.first);
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting mashaf info: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
    return null;
  }

  Future<List<MashafPageLine>> getPageLines(int pageNumber) async {
    try {
      final layoutDb = await layoutDatabase;
      final wordsDb = await wordsDatabase;

      // Get lines for the page from layout database
      final List<Map<String, dynamic>> lineMaps = await layoutDb.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC',
      );

      final List<MashafPageLine> lines = [];

      // Helper to safely parse int from dynamic
      int? parseIntOrNull(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          if (value.isEmpty) return null;
          return int.tryParse(value);
        }
        return null;
      }

      for (var lineMap in lineMaps) {
        final int? firstWordId = parseIntOrNull(lineMap['first_word_id']);
        final int? lastWordId = parseIntOrNull(lineMap['last_word_id']);

        List<MashafWord> words = [];

        // Only fetch words if both IDs are valid
        if (firstWordId != null &&
            lastWordId != null &&
            firstWordId > 0 &&
            lastWordId > 0) {
          final List<Map<String, dynamic>> wordMaps = await wordsDb.query(
            'words',
            where: 'id >= ? AND id <= ?',
            whereArgs: [firstWordId, lastWordId],
            orderBy: 'id ASC',
          );

          words = wordMaps.map((map) {
            final mutableMap = Map<String, dynamic>.from(map);
            final surah = (map['sura'] ?? map['surah'] ?? map['chapter_id']);
            final ayah = (map['ayah'] ?? map['verse_id']);
            int wordNum = 0;
            if (map.containsKey('word_position') &&
                map['word_position'] != null) {
              wordNum = map['word_position'] as int;
            } else if (map.containsKey('word') && map['word'] != null) {
              wordNum = map['word'] as int;
            }

            // Inject JSON Tajweed data if available
            if (surah is int && ayah is int && wordNum > 0) {
              final tajweed = TajweedDataProvider().getTajweed(
                surah,
                ayah,
                wordNum,
                map['text'] as String,
              );
              if (tajweed != null) {
                mutableMap['text_tajweed'] = tajweed;
              }
            }

            return MashafWord.fromMap(mutableMap);
          }).toList();
        }

        lines.add(MashafPageLine.fromMap(lineMap, words));
      }

      return lines;
    } catch (e) {
      debugPrint('Error getting page lines: $e');
      return [];
    }
  }

  Future<int> getSurahStartPage(int surahNumber) async {
    try {
      final db = await layoutDatabase;
      final List<Map<String, dynamic>> result = await db.query(
        'pages',
        columns: ['page_number'],
        where: 'surah_number = ?',
        whereArgs: [surahNumber],
        orderBy: 'page_number ASC, line_number ASC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['page_number'] as int;
      }
    } catch (e) {
      debugPrint('Error getting surah start page: $e');
    }
    return 1;
  }

  Future<int> getSurahForPage(int pageNumber) async {
    try {
      final db = await layoutDatabase;
      final List<Map<String, dynamic>> result = await db.query(
        'pages',
        columns: ['surah_number'],
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final val = result.first['surah_number'];
        if (val is int) return val;
        if (val is String) return int.tryParse(val) ?? 1;
      }
    } catch (e) {
      debugPrint('Error getting surah for page: $e');
    }
    return 1;
  }

  Future<int> getPageForAyah(int surahNumber, int ayahNumber) async {
    try {
      // 1. Find the first word ID for this Ayah
      final wordsDb = await wordsDatabase;
      final List<Map<String, dynamic>> wordResult = await wordsDb.query(
        'words',
        columns: ['id', 'page_number'], // Request page_number if it exists
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        orderBy: 'id ASC',
        limit: 1,
      );

      if (wordResult.isEmpty) return 0;

      // Note: The words DB might already have page_number!
      if (wordResult.first.containsKey('page_number') &&
          wordResult.first['page_number'] != null) {
        final page = wordResult.first['page_number'];
        if (page is int && page > 0) return page;
        if (page is String) {
          final p = int.tryParse(page);
          if (p != null && p > 0) return p;
        }
      }

      final int wordId = wordResult.first['id'] as int;

      // 2. Find the page containing this word in layout DB
      final layoutDb = await layoutDatabase;
      final List<Map<String, dynamic>> pageResult = await layoutDb.query(
        'pages',
        columns: ['page_number'],
        where: 'first_word_id <= ? AND last_word_id >= ?',
        whereArgs: [wordId, wordId],
        limit: 1,
      );

      if (pageResult.isNotEmpty) {
        final val = pageResult.first['page_number'];
        if (val is int) return val;
        if (val is String) return int.tryParse(val) ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting page for ayah: $e');
    }
    return 0;
  }

  Future<void> close() async {
    if (_layoutDatabase != null) {
      await _layoutDatabase!.close();
      _layoutDatabase = null;
    }
    if (_wordsDatabase != null) {
      await _wordsDatabase!.close();
      _wordsDatabase = null;
    }
  }
}
