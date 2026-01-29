import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class UserDataDatabase {
  static Database? _database;
  static const String _dbName = 'user_data.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for tracking daily reading progress
        await db.execute('''
          CREATE TABLE reading_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            surah_id INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');

        // Table for Khatam plans
        await db.execute('''
          CREATE TABLE khatam_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target_date TEXT NOT NULL,
            start_date TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            goal_type TEXT NOT NULL, -- 'days', 'pages_per_day', etc.
            goal_value INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_reading_stats_date ON reading_stats(date);
        ''');
      },
    );
  }

  // Reading Stats
  static Future<void> recordReading(int surahId, int verseNumber) async {
    final db = await database;
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Check if already recorded today
    final existing = await db.query(
      'reading_stats',
      where: 'date = ? AND surah_id = ? AND verse_number = ?',
      whereArgs: [date, surahId, verseNumber],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('reading_stats', {
        'date': date,
        'surah_id': surahId,
        'verse_number': verseNumber,
        'timestamp': now.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> recordBulkReading(List<Map<String, int>> readings) async {
    final db = await database;
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final batch = db.batch();
    for (var reading in readings) {
      final surahId = reading['surahId']!;
      final verseNumber = reading['verseNumber']!;

      // We still need to check for duplicates.
      // For Batch, it's harder to check existing inside.
      // Better: filter before batch or use INSERT OR IGNORE with unique index.
      // Let's add a unique index to the table in a future migration,
      // but for now, let's do a simple check.

      batch.rawInsert(
        '''
        INSERT INTO reading_stats (date, surah_id, verse_number, timestamp)
        SELECT ?, ?, ?, ?
        WHERE NOT EXISTS (
          SELECT 1 FROM reading_stats 
          WHERE date = ? AND surah_id = ? AND verse_number = ?
        )
      ''',
        [
          date,
          surahId,
          verseNumber,
          now.millisecondsSinceEpoch,
          date,
          surahId,
          verseNumber,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getDailyStats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT date, COUNT(*) as verses_count 
      FROM reading_stats 
      GROUP BY date 
      ORDER BY date DESC
    ''');
  }

  static Future<void> clearAllStats() async {
    final db = await database;
    await db.delete('reading_stats');
  }

  // Khatam Plans
  static Future<void> createPlan(Map<String, dynamic> plan) async {
    final db = await database;
    await db.insert('khatam_plans', plan);
  }

  static Future<List<Map<String, dynamic>>> getPlans() async {
    final db = await database;
    return await db.query('khatam_plans', orderBy: 'id DESC');
  }

  static Future<void> clearAllPlans() async {
    final db = await database;
    await db.delete('khatam_plans');
  }
}
