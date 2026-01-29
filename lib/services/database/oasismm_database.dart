import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central database provider for OasisMM consolidated database.
/// All services should use this class to access the database.
class OasisMMDatabase {
  static Database? _database;
  static const String _dbName = 'oasismm.db';

  /// Get the database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database - copy from assets if not exists
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Check if database already exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);

        // Copy database from assets
        final ByteData data = await rootBundle.load('assets/$_dbName');
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception('Failed to copy database from assets: $e');
      }
    }

    // Open database
    return openDatabase(path, readOnly: true);
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete and recreate database (for updates)
  static Future<void> resetDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }

    _database = await _initDatabase();
  }

  // ============================================
  // HADITH QUERIES
  // ============================================

  /// Get all hadith books
  static Future<List<Map<String, dynamic>>> getHadithBooks() async {
    final db = await database;
    return db.query('hadith_books', orderBy: 'id');
  }

  /// Get hadith book by key
  static Future<Map<String, dynamic>?> getHadithBookByKey(
    String bookKey,
  ) async {
    final db = await database;
    final results = await db.query(
      'hadith_books',
      where: 'book_key = ?',
      whereArgs: [bookKey],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get chapters for a book
  static Future<List<Map<String, dynamic>>> getHadithChapters(
    int bookId,
  ) async {
    final db = await database;
    return db.query(
      'hadith_chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'chapter_number',
    );
  }

  /// Get hadiths by chapter
  static Future<List<Map<String, dynamic>>> getHadithsByChapter(
    int bookId,
    int chapterId,
  ) async {
    final db = await database;
    return db.query(
      'hadiths',
      where: 'book_id = ? AND chapter_id = ?',
      whereArgs: [bookId, chapterId],
      orderBy: 'hadith_number',
    );
  }

  /// Get hadith by number
  static Future<Map<String, dynamic>?> getHadithByNumber(
    int bookId,
    String hadithNumber,
  ) async {
    final db = await database;
    final results = await db.query(
      'hadiths',
      where: 'book_id = ? AND hadith_number = ?',
      whereArgs: [bookId, hadithNumber],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all hadiths for a book
  static Future<List<Map<String, dynamic>>> getAllHadithsForBook(
    int bookId,
  ) async {
    final db = await database;
    return db.query(
      'hadiths',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'hadith_number',
    );
  }

  // ============================================
  // TAFSEER QUERIES
  // ============================================

  /// Get tafseer for an ayah
  static Future<List<Map<String, dynamic>>> getTafseer(
    int surahId,
    int ayahNumber,
    String language,
  ) async {
    final db = await database;
    return db.query(
      'tafseer',
      where:
          'surah_id = ? AND verse_start <= ? AND (verse_end >= ? OR verse_end IS NULL) AND language = ?',
      whereArgs: [surahId, ayahNumber, ayahNumber, language],
    );
  }

  /// Get all tafseer for a surah
  static Future<List<Map<String, dynamic>>> getTafseerForSurah(
    int surahId,
    String language,
  ) async {
    final db = await database;
    return db.query(
      'tafseer',
      where: 'surah_id = ? AND language = ?',
      whereArgs: [surahId, language],
      orderBy: 'verse_start',
    );
  }

  // ============================================
  // SUNNAH QUERIES
  // ============================================

  /// Get sunnah book info
  static Future<Map<String, dynamic>?> getSunnahBookInfo() async {
    final db = await database;
    final results = await db.query('sunnah_book_info', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all sunnah chapters
  static Future<List<Map<String, dynamic>>> getSunnahChapters() async {
    final db = await database;
    return db.query('sunnah_chapters', orderBy: 'chapter_number');
  }

  /// Get sunnah items by chapter
  static Future<List<Map<String, dynamic>>> getSunnahItems(
    int chapterId,
  ) async {
    final db = await database;
    return db.query(
      'sunnah_items',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'item_number',
    );
  }

  /// Get all sunnah items
  static Future<List<Map<String, dynamic>>> getAllSunnahItems() async {
    final db = await database;
    return db.query('sunnah_items', orderBy: 'chapter_id, item_number');
  }

  // ============================================
  // ALLAH NAMES QUERIES
  // ============================================

  /// Get all 99 names of Allah
  static Future<List<Map<String, dynamic>>> getAllahNames() async {
    final db = await database;
    return db.query('allah_names', orderBy: 'id');
  }

  // ============================================
  // DUA/MUNAJAT QUERIES
  // ============================================

  /// Get all dua categories
  static Future<List<Map<String, dynamic>>> getDuaCategories() async {
    final db = await database;
    return db.query('dua_categories');
  }

  /// Get duas by category
  static Future<List<Map<String, dynamic>>> getDuasByCategory(
    int categoryId, {
    String? language,
  }) async {
    final db = await database;
    if (language != null) {
      return db.query(
        'duas',
        where: 'category_id = ? AND language = ?',
        whereArgs: [categoryId, language],
      );
    }
    return db.query('duas', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  /// Get all munajat entries
  static Future<List<Map<String, dynamic>>> getMunajat() async {
    final db = await database;
    return db.query('munajat');
  }

  // ============================================
  // QURAN QUERIES
  // ============================================

  /// Get all surahs
  static Future<List<Map<String, dynamic>>> getSurahs() async {
    final db = await database;
    return db.query('surahs', orderBy: 'id');
  }

  /// Get verses for a surah
  static Future<List<Map<String, dynamic>>> getVerses(int surahId) async {
    final db = await database;
    return db.query(
      'verses',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'verse_number',
    );
  }

  /// Get translations for a surah
  static Future<List<Map<String, dynamic>>> getTranslations(
    int surahId,
    String translatorKey,
  ) async {
    final db = await database;
    return db.query(
      'translations',
      where: 'surah_id = ? AND translator_key = ?',
      whereArgs: [surahId, translatorKey],
      orderBy: 'verse_number',
    );
  }

  /// Get surah info
  static Future<Map<String, dynamic>?> getSurahInfo(
    int surahId,
    String language,
  ) async {
    final db = await database;
    final results = await db.query(
      'surah_info',
      where: 'surah_id = ? AND language = ?',
      whereArgs: [surahId, language],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get ayah metadata (juz, hizb, rub, page)
  static Future<Map<String, dynamic>?> getAyahMetadata(
    int surahId,
    int verseNumber,
  ) async {
    final db = await database;
    final results = await db.query(
      'quran_ayah_metadata',
      where: 'surah_id = ? AND verse_number = ?',
      whereArgs: [surahId, verseNumber],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get sajda positions
  static Future<List<Map<String, dynamic>>> getSajdaPositions() async {
    final db = await database;
    return db.query('quran_sajda');
  }

  // ============================================
  // INDOPAK WORDS QUERIES
  // ============================================

  /// Get IndoPak words for a surah
  static Future<List<Map<String, dynamic>>> getIndopakWords(int surahId) async {
    final db = await database;
    return db.query(
      'indopak_words',
      where: 'surah = ?',
      whereArgs: [surahId],
      orderBy: 'ayah, word',
    );
  }

  /// Get IndoPak words for a specific ayah
  static Future<List<Map<String, dynamic>>> getIndopakWordsForAyah(
    int surahId,
    int ayahNumber,
  ) async {
    final db = await database;
    return db.query(
      'indopak_words',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surahId, ayahNumber],
      orderBy: 'word',
    );
  }

  /// Get IndoPak words in a specific ID range
  static Future<List<Map<String, dynamic>>> getIndopakWordsInRange(
    int startId,
    int endId,
  ) async {
    final db = await database;
    return db.query(
      'indopak_words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [startId, endId],
      orderBy: 'id',
    );
  }

  // ============================================
  // QPC GLYPHS QUERIES
  // ============================================

  /// Get QPC glyphs for a page
  static Future<List<Map<String, dynamic>>> getQpcGlyphsForPage(
    int page,
  ) async {
    final db = await database;
    return db.query(
      'qpc_glyphs',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'line, word',
    );
  }

  // ============================================
  // MASHAF LAYOUT QUERIES
  // ============================================

  /// Get Mashaf page layout
  static Future<List<Map<String, dynamic>>> getMashafPage(
    int pageNumber,
  ) async {
    final db = await database;
    return db.query(
      'mashaf_pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line',
    );
  }
}
