class HadithBook {
  final int id;
  final Map<String, dynamic> metadata;
  final List<Chapter> chapters;

  HadithBook({
    required this.id,
    required this.metadata,
    required this.chapters,
  });

  factory HadithBook.fromJson(Map<String, dynamic> json) {
    return HadithBook(
      id: json['id'] ?? 0,
      metadata: json['metadata'] ?? {},
      chapters:
          (json['chapters'] as List?)
              ?.map((c) => Chapter.fromJson(c))
              .toList() ??
          [],
    );
  }

  String get name => metadata['english']?['title'] ?? '';
}

class Chapter {
  final int id;
  final int bookId;
  final String arabic;
  final String english;

  Chapter({
    required this.id,
    required this.bookId,
    required this.arabic,
    required this.english,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      bookId: json['bookId'] ?? 0,
      arabic: json['arabic']?.toString() ?? '',
      english: json['english']?.toString() ?? '',
    );
  }
}
