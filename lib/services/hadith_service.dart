import '../models/hadith.dart';
import '../models/hadith_book.dart';
import 'database/oasismm_database.dart';

class HadithService {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  // Cache for book data
  final Map<String, HadithBook> _bookCache = {};
  final Map<String, List<Hadith>> _hadithCache = {};

  static const Map<String, String> bookNames = {
    'bukhari': 'Sahih al Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abu Dawud',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'nasai': "Sunan an-Nasa'i",
    'ibnmajah': 'Sunan Ibn Majah',
    'malik': 'Muwatta Malik',
    'ahmed': 'Musnad Ahmed',
    'darimi': 'Sunan Darimi',
  };

  Future<HadithBook> getBookMetadata(String bookKey) async {
    if (_bookCache.containsKey(bookKey)) {
      return _bookCache[bookKey]!;
    }

    final bookData = await OasisMMDatabase.getHadithBookByKey(bookKey);
    if (bookData == null) {
      throw Exception('Book not found: $bookKey');
    }

    final bookId = bookData['id'] as int;
    final chapters = await OasisMMDatabase.getHadithChapters(bookId);

    final book = HadithBook(
      id: bookId,
      metadata: {
        'english': {
          'title': bookData['name_english'] ?? bookNames[bookKey] ?? bookKey,
        },
        'arabic': {'title': bookData['name_arabic'] ?? ''},
        'author': bookData['author_english'] ?? '',
      },
      chapters: chapters
          .map(
            (c) => Chapter(
              id: c['id'] as int,
              bookId: bookId,
              english: c['name_english'] ?? '',
              arabic: c['name_arabic'] ?? '',
            ),
          )
          .toList(),
    );

    _bookCache[bookKey] = book;
    return book;
  }

  Future<List<Hadith>> getHadithsByChapter(
    String bookKey,
    int chapterId,
  ) async {
    try {
      final cacheKey = '${bookKey}_$chapterId';
      if (_hadithCache.containsKey(cacheKey)) {
        return _hadithCache[cacheKey]!;
      }

      final bookData = await OasisMMDatabase.getHadithBookByKey(bookKey);
      if (bookData == null) return [];

      final bookId = bookData['id'] as int;
      final hadithRows = await OasisMMDatabase.getHadithsByChapter(
        bookId,
        chapterId,
      );

      final hadiths = hadithRows.map((h) => Hadith.fromDbRow(h)).toList();
      _hadithCache[cacheKey] = hadiths;

      return hadiths;
    } catch (e) {
      return [];
    }
  }

  Future<Hadith?> getHadithByNumber(
    String bookKey,
    dynamic hadithNumber,
  ) async {
    try {
      final bookData = await OasisMMDatabase.getHadithBookByKey(bookKey);
      if (bookData == null) return null;

      final bookId = bookData['id'] as int;
      final searchStr = hadithNumber.toString().trim();

      // Try exact match first
      final hadithRow = await OasisMMDatabase.getHadithByNumber(
        bookId,
        searchStr,
      );
      if (hadithRow != null) {
        return Hadith.fromDbRow(hadithRow);
      }

      // Fallback: search in all hadiths for partial match
      final allHadiths = await OasisMMDatabase.getAllHadithsForBook(bookId);
      final regex = RegExp('^$searchStr[a-z]*\$', caseSensitive: false);

      for (final h in allHadiths) {
        final id = h['hadith_number']?.toString() ?? '';
        if (id == searchStr || regex.hasMatch(id)) {
          return Hadith.fromDbRow(h);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _bookCache.clear();
    _hadithCache.clear();
  }
}
