import 'package:flutter/foundation.dart';
import '../models/mashaf_models.dart';
import 'database/oasismm_database.dart';
import 'dart:convert';

class MashafService {
  Future<MashafInfo?> getMashafInfo() async {
    try {
      final pages = await OasisMMDatabase.getMashafPage(1);
      if (pages.isNotEmpty) {
        return MashafInfo(
          name: 'Indopak 15 lines(Qudratullah)',
          numberOfPages: 610,
          linesPerPage: 15,
          fontName: 'indopak-nastaleeq',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting mashaf info: $e');
      debugPrint(stackTrace.toString());
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  Future<List<MashafPageLine>> getPageLines(int pageNumber) async {
    try {
      // Get layout data for this page
      final layoutData = await OasisMMDatabase.getMashafPage(pageNumber);

      if (layoutData.isEmpty) {
        debugPrint('No layout data for page $pageNumber');
        return [];
      }

      final List<MashafPageLine> lines = [];

      // Group by line
      final lineGroups = <int, List<Map<String, dynamic>>>{};
      for (var row in layoutData) {
        final lineNum = _toInt(row['line']) ?? 0;
        lineGroups.putIfAbsent(lineNum, () => []);
        lineGroups[lineNum]!.add(row);
      }

      for (var lineNum in lineGroups.keys.toList()..sort()) {
        final lineData = lineGroups[lineNum]!.first;

        // Parse data_json if available
        Map<String, dynamic> jsonData = {};
        if (lineData['data_json'] != null) {
          try {
            jsonData = json.decode(lineData['data_json'] as String);
          } catch (_) {}
        }

        final surah =
            _toInt(lineData['surah']) ??
            _toInt(jsonData['sura']) ??
            _toInt(jsonData['surah_number']) ??
            0;
        final firstWordId = _toInt(jsonData['first_word_id']) ?? 0;
        final lastWordId = _toInt(jsonData['last_word_id']) ?? 0;

        List<MashafWord> words = [];

        if (firstWordId > 0 && lastWordId > 0) {
          // Fetch words in range from indopak_words table
          // This avoids duplicating ayahs that span multiple lines
          final wordRows = await OasisMMDatabase.getIndopakWordsInRange(
            firstWordId,
            lastWordId,
          );

          words = wordRows.map((wordMap) {
            return MashafWord.fromMap(wordMap);
          }).toList();
        }

        lines.add(
          MashafPageLine(
            pageNumber: pageNumber,
            lineNumber: lineNum,
            lineType: jsonData['line_type']?.toString() ?? 'normal',
            isCentered:
                jsonData['is_centered'] == 1 || jsonData['is_centered'] == true,
            firstWordId: firstWordId,
            lastWordId: lastWordId,
            surahNumber: surah,
            words: words,
          ),
        );
      }

      return lines;
    } catch (e) {
      debugPrint('Error getting page lines: $e');
      return [];
    }
  }

  Future<int> getSurahStartPage(int surahNumber) async {
    try {
      final db = await OasisMMDatabase.database;
      final result = await db.query(
        'mashaf_pages',
        columns: ['page_number'],
        where: 'surah = ?',
        whereArgs: [surahNumber],
        orderBy: 'page_number ASC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['page_number'] as int? ?? 1;
      }
    } catch (e) {
      debugPrint('Error getting surah start page: $e');
    }
    return 1;
  }

  Future<int> getSurahForPage(int pageNumber) async {
    try {
      final pages = await OasisMMDatabase.getMashafPage(pageNumber);
      if (pages.isNotEmpty) {
        return pages.first['surah'] as int? ?? 1;
      }
    } catch (e) {
      debugPrint('Error getting surah for page: $e');
    }
    return 1;
  }

  Future<int> getPageForAyah(int surahNumber, int ayahNumber) async {
    try {
      final db = await OasisMMDatabase.database;
      final result = await db.query(
        'mashaf_pages',
        columns: ['page_number'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['page_number'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting page for ayah: $e');
    }
    return 0;
  }

  Future<List<Map<String, int>>> getVersesOnPage(int pageNumber) async {
    try {
      final lines = await getPageLines(pageNumber);
      final Set<String> uniqueVerses = {};
      final List<Map<String, int>> results = [];

      for (var line in lines) {
        for (var word in line.words) {
          final key = '${word.surah}:${word.ayah}';
          if (!uniqueVerses.contains(key)) {
            uniqueVerses.add(key);
            results.add({'surahId': word.surah, 'verseNumber': word.ayah});
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error getting verses on page: $e');
      return [];
    }
  }

  Future<void> close() async {
    // No separate databases to close - using OasisMMDatabase
  }
}
