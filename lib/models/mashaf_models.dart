class MashafInfo {
  final String name;
  final int numberOfPages;
  final int linesPerPage;
  final String fontName;

  MashafInfo({
    required this.name,
    required this.numberOfPages,
    required this.linesPerPage,
    required this.fontName,
  });

  factory MashafInfo.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse int from dynamic (handles both int and String)
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MashafInfo(
      name: (map['name'] ?? '').toString(),
      numberOfPages: parseIntSafe(map['number_of_pages']),
      linesPerPage: parseIntSafe(map['lines_per_page']),
      fontName: (map['font_name'] ?? '').toString(),
    );
  }
}

class MashafPageLine {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int firstWordId;
  final int lastWordId;
  final int surahNumber;
  final List<MashafWord> words;

  MashafPageLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.firstWordId,
    required this.lastWordId,
    required this.surahNumber,
    required this.words,
  });

  factory MashafPageLine.fromMap(
    Map<String, dynamic> map,
    List<MashafWord> words,
  ) {
    // Helper to safely parse int from dynamic (handles both int and String)
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MashafPageLine(
      pageNumber: parseIntSafe(map['page_number']),
      lineNumber: parseIntSafe(map['line_number']),
      lineType: (map['line_type'] ?? '').toString(),
      isCentered: parseIntSafe(map['is_centered']) == 1,
      firstWordId: parseIntSafe(map['first_word_id']),
      lastWordId: parseIntSafe(map['last_word_id']),
      surahNumber: parseIntSafe(map['surah_number']),
      words: words,
    );
  }
}

class MashafWord {
  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;
  final String? textTajweed;

  MashafWord({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
    this.textTajweed,
  });

  factory MashafWord.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse int from dynamic (handles both int and String)
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MashafWord(
      id: parseIntSafe(map['id']),
      location: (map['location'] ?? '').toString(),
      surah: parseIntSafe(map['surah']),
      ayah: parseIntSafe(map['ayah']),
      // Handle both 'word' and 'word_position' column names
      word: parseIntSafe(map['word_position'] ?? map['word']),
      text: (map['text'] ?? '').toString(),
      textTajweed: map['text_tajweed']?.toString(),
    );
  }
}
