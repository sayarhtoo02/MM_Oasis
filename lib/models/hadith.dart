class HadithReferences {
  final String reference;
  final String inBookReference;
  final String uscMsaWebReference;

  HadithReferences({
    required this.reference,
    required this.inBookReference,
    required this.uscMsaWebReference,
  });

  factory HadithReferences.fromJson(Map<String, dynamic> json) {
    return HadithReferences(
      reference: json['reference']?.toString() ?? '',
      inBookReference: json['inBookReference']?.toString() ?? '',
      uscMsaWebReference: json['uscMsaWebReference']?.toString() ?? '',
    );
  }
}

class HadithChapterInfo {
  final String english;
  final String arabic;
  final String number;

  HadithChapterInfo({
    required this.english,
    required this.arabic,
    required this.number,
  });

  factory HadithChapterInfo.fromJson(Map<String, dynamic> json) {
    return HadithChapterInfo(
      english: json['english']?.toString() ?? '',
      arabic: json['arabic']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
    );
  }
}

class Hadith {
  final int id;
  final dynamic idInBook;
  final int chapterId;
  final int bookId;
  final String arabic;
  final Map<String, String> english;
  final Map<String, String> burmese;
  final HadithReferences? references;
  final HadithChapterInfo? chapterInfo;
  final dynamic sunnahHadithId;

  Hadith({
    required this.id,
    required this.idInBook,
    required this.chapterId,
    required this.bookId,
    required this.arabic,
    required this.english,
    required this.burmese,
    this.references,
    this.chapterInfo,
    this.sunnahHadithId,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] ?? 0,
      idInBook: json['idInBook'] ?? 0,
      chapterId: json['chapterId'] ?? 0,
      bookId: json['bookId'] ?? 0,
      arabic: json['arabic'] ?? '',
      english:
          (json['english'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v?.toString() ?? ''),
          ) ??
          {},
      burmese:
          (json['burmese'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v?.toString() ?? ''),
          ) ??
          {},
      references: json['references'] != null
          ? HadithReferences.fromJson(json['references'])
          : null,
      chapterInfo: json['chapter'] != null
          ? HadithChapterInfo.fromJson(json['chapter'])
          : null,
      sunnahHadithId: json['sunnahHadithId'],
    );
  }

  /// Factory constructor for database rows
  factory Hadith.fromDbRow(Map<String, dynamic> row) {
    return Hadith(
      id: row['id'] ?? 0,
      idInBook: row['hadith_number'] ?? row['id'] ?? 0,
      chapterId: row['chapter_id'] ?? 0,
      bookId: row['book_id'] ?? 0,
      arabic: row['text_arabic'] ?? '',
      english: {
        'narrator': row['narrator_english'] ?? '',
        'text': row['text_english'] ?? '',
      },
      burmese: {
        'narrator': row['narrator_myanmar'] ?? '',
        'text': row['text_myanmar'] ?? '',
      },
      references: row['reference'] != null
          ? HadithReferences(
              reference: row['reference'] ?? '',
              inBookReference: '',
              uscMsaWebReference: '',
            )
          : null,
      chapterInfo:
          row['chapter_english'] != null ||
              row['chapter_arabic'] != null ||
              row['chapter_number'] != null
          ? HadithChapterInfo(
              english: row['chapter_english'] ?? '',
              arabic: row['chapter_arabic'] ?? '',
              number: row['chapter_number'] ?? '',
            )
          : null,
      sunnahHadithId: null,
    );
  }
}
