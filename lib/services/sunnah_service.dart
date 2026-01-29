import 'dart:convert';
import 'package:munajat_e_maqbool_app/models/sunnah_collection_model.dart';
import 'package:munajat_e_maqbool_app/models/book_info_model.dart';
import 'database/oasismm_database.dart';

class SunnahService {
  Future<BookInfo?> getBookInfo() async {
    try {
      final row = await OasisMMDatabase.getSunnahBookInfo();
      if (row == null) return null;

      return BookInfo(
        title: row['title'] ?? '',
        author: row['author'] ?? '',
        publisher: row['publisher'] ?? '',
        language: row['language'] ?? '',
        edition: row['edition'] ?? '',
        contact: ContactInfo(
          phone: row['phone'] ?? '',
          mobile: row['mobile'] ?? '',
          email: row['email'] ?? '',
        ),
      );
    } catch (e) {
      print('Error loading book info: $e');
      return null;
    }
  }

  Future<List<SunnahChapter>> getAllChapters() async {
    try {
      final chapterRows = await OasisMMDatabase.getSunnahChapters();

      List<SunnahChapter> chapters = [];
      for (final c in chapterRows) {
        final chapterId = c['id'] as int;
        final itemRows = await OasisMMDatabase.getSunnahItems(chapterId);

        chapters.add(
          SunnahChapter(
            chapterId: c['chapter_number'] ?? chapterId,
            chapterTitle: c['title'] ?? '',
            items: itemRows.map((item) => _itemFromRow(item)).toList(),
          ),
        );
      }

      return chapters;
    } catch (e) {
      print('Error loading chapters: $e');
      return [];
    }
  }

  SunnahItem _itemFromRow(Map<String, dynamic> row) {
    // Parse notes and references from JSON if stored as string
    List<SunnahNote> notes = [];
    List<String> references = [];

    try {
      if (row['notes_json'] != null) {
        final notesList = json.decode(row['notes_json'] as String);
        notes = (notesList as List)
            .map(
              (e) => SunnahNote(type: e['type'] ?? '', text: e['text'] ?? ''),
            )
            .toList();
      }
    } catch (_) {}

    try {
      if (row['references_json'] != null) {
        final refList = json.decode(row['references_json'] as String);
        references = (refList as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return SunnahItem(
      id: row['item_number'] ?? row['id'] ?? 0,
      text: row['text'] ?? '',
      arabicText: row['arabic_text'],
      urduTranslation: row['urdu_translation'],
      notes: notes,
      references: references,
    );
  }
}
