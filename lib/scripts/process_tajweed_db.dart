import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../services/tajweed/tajweed_rule.dart';

// Mapping from JSON XML-like tags to TajweedRule
final Map<String, TajweedRule> ruleMapping = {
  'ghunnah': TajweedRule.ghunna,
  'idgham_ghunnah': TajweedRule.idghamWithGhunna,
  'idgham_wo_ghunnah': TajweedRule.idghamWithoutGhunna,
  'ikhafa': TajweedRule.ikhfaa,
  'ikhafa_shafawi':
      TajweedRule.ikhfaa, // Treating Shafawi same as normal Ikhfaa (Red)
  'iqlab': TajweedRule.iqlab,
  'qalaqah': TajweedRule.qalqala,
  'ham_wasl': TajweedRule.hamzatulWasli,
  'laam_shamsiyah': TajweedRule.lamShamsiyyah,
  'slnt': TajweedRule.silent, // Silent letters
  'madda_normal': TajweedRule.prolonging,
  'madda_permissible': TajweedRule.prolonging,
  'madda_necessary': TajweedRule.prolonging,
  'madda_obligatory_monfasel': TajweedRule.prolonging,
  'madda_obligatory_mottasel': TajweedRule.prolonging,
  // 'custom-alef-maksora': treated as text often, or prolonging if wrapped.
  // 'rule' class handling will check for these keys.
};

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 1. JSON Source File
  final jsonPath = join(Directory.current.path, 'quran_tajweed_api.json');
  if (!File(jsonPath).existsSync()) {
    print('Error: JSON file not found at $jsonPath');
    return;
  }

  // 2. Database Target
  final dbPath = join(
    Directory.current.path,
    'assets',
    'quran_data',
    'quran_scripts',
    'indopak-nastaleeq.db',
  );
  print('Target database: $dbPath');

  if (!File(dbPath).existsSync()) {
    print('Error: Database file not found at $dbPath');
    return;
  }

  // 3. Load JSON Data
  print('Loading JSON data... (this might take a moment)');
  final jsonString = await File(jsonPath).readAsString();
  final List<dynamic> jsonData = json.decode(jsonString);
  print('Loaded ${jsonData.length} words from JSON.');

  // Create a map for fast lookup: "surah:ayah:word" -> tajweed_text
  final Map<String, String> tajweedMap = {};
  for (final item in jsonData) {
    if (item is Map<String, dynamic>) {
      final key = '${item['surah']}:${item['ayah']}:${item['word']}';
      tajweedMap[key] = item['text_tajweed'] ?? '';
    }
  }

  // 4. Open Database
  final db = await openDatabase(dbPath);

  // Check/Add column
  final tableInfo = await db.rawQuery("PRAGMA table_info(words)");
  final hasColumn = tableInfo.any((col) => col['name'] == 'text_tajweed');
  if (!hasColumn) {
    print('Adding text_tajweed column...');
    await db.execute('ALTER TABLE words ADD COLUMN text_tajweed TEXT');
  }

  // 5. Process Words
  print('Fetching existing words from DB...');
  final dbWords = await db.query('words');
  print('Total words in DB: ${dbWords.length}');

  var batch = db.batch();
  int updateCount = 0;
  int missingCount = 0;

  for (final wordRow in dbWords) {
    final id = wordRow['id'] as int;
    final surah =
        (wordRow['sura'] ?? wordRow['surah'] ?? wordRow['chapter_id']) as int;
    final ayah = (wordRow['ayah'] ?? wordRow['verse_id']) as int;
    // Handle word position - DB column might be 'word' or 'word_position' or just 'word' rank
    // Assuming 'word' in DB matches 'word' in JSON.
    // Important: check if 'word_position' exists, otherwise use 'word'.
    // Looking at mashaf_models.dart, it tries 'word_position' then 'word'.
    // In process_tajweed_db (original), it didn't use 'word' column for logic, just text.
    // Here we need exact word matching.
    int wordNum = 0;
    if (wordRow.containsKey('word_position') &&
        wordRow['word_position'] != null) {
      wordNum = wordRow['word_position'] as int;
    } else if (wordRow.containsKey('word') && wordRow['word'] != null) {
      wordNum = wordRow['word'] as int;
    }

    if (wordNum == 0) {
      // Fallback or skip?
      // Might be 0-indexed in DB but 1-indexed in JSON?
      // Usually Quran word positions are 1-based.
      // Let's assume 1-based. If DB has 0, increment?
      // Let's rely on exact match key first.
      // If db wordNum is 0, let's look at next item.
      // Often DBs use 1-based.
    }

    final key = '$surah:$ayah:$wordNum';
    final jsonTajweed = tajweedMap[key];

    if (jsonTajweed != null && jsonTajweed.isNotEmpty) {
      final serialized = parseAndSerialize(
        jsonTajweed,
        wordRow['text'] as String,
      );
      batch.update(
        'words',
        {'text_tajweed': serialized},
        where: 'id = ?',
        whereArgs: [id],
      );
      updateCount++;
    } else {
      missingCount++;
      // Optional: keep existing text or clear it?
      // Better to check if we can match by text if number mismatch?
      // For now, simple key match.
    }

    if (updateCount % 1000 == 0 && updateCount > 0) {
      print('Committing $updateCount updates so far...');
      await batch.commit(noResult: true);
      batch = db.batch(); // Create new batch for next chunk
    }
  }

  await batch.commit(noResult: true);
  await db.close();

  print('Finished.');
  print('Updated words: $updateCount');
  print('Missing/Skipped: $missingCount');
}

/// Parses the XML-like Tajweed text (e.g. "<rule class=ghunnah>نّ</rule>")
/// and serializes it to "text:ruleIndex|text:ruleIndex" format
String parseAndSerialize(String tajweedText, String originalText) {
  // Regex to match <rule class=...>(content)</rule> and plain text parts
  // We need to tokenize the string.
  // Patter: (<rule class=([^>]+)>([^<]+)</rule>)|([^<]+)

  final regExp = RegExp(r'<rule class=([^>]+)>([^<]+)</rule>|([^<]+)');
  final matches = regExp.allMatches(tajweedText);

  final List<String> segments = [];

  for (final match in matches) {
    if (match.group(1) != null) {
      // It's a rule match
      final className = match.group(1)!;
      final content = match.group(2)!;
      final rule = ruleMapping[className] ?? TajweedRule.none;
      segments.add('$content:${rule.index}');
    } else if (match.group(3) != null) {
      // It's plain text (outside rules)
      final content = match.group(3)!;
      segments.add('$content:${TajweedRule.none.index}');
    }
  }

  return segments.join('|');
}
