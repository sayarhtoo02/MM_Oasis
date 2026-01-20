class SunnahChapter {
  final int chapterId;
  final String chapterTitle;
  final List<SunnahItem> items;

  SunnahChapter({
    required this.chapterId,
    required this.chapterTitle,
    required this.items,
  });

  factory SunnahChapter.fromJson(Map<String, dynamic> json) {
    return SunnahChapter(
      chapterId: json['chapter_id'] as int,
      chapterTitle: json['chapter_title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => SunnahItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SunnahNote {
  final String type;
  final String text;

  SunnahNote({required this.type, required this.text});

  factory SunnahNote.fromJson(Map<String, dynamic> json) {
    return SunnahNote(
      type: json['type'] as String,
      text: json['text'] as String,
    );
  }
}

class SunnahItem {
  final int id;
  final String text;
  final String? arabicText;
  final String? urduTranslation;
  final List<SunnahNote> notes;
  final List<String> references;

  SunnahItem({
    required this.id,
    required this.text,
    this.arabicText,
    this.urduTranslation,
    this.notes = const [],
    required this.references,
  });

  factory SunnahItem.fromJson(Map<String, dynamic> json) {
    return SunnahItem(
      id: json['id'] as int,
      text: json['text'] as String,
      arabicText: json['arabic_text'] as String?,
      urduTranslation: json['urdu_translation'] as String?,
      notes:
          (json['notes'] as List<dynamic>?)
              ?.map((e) => SunnahNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      references:
          (json['references'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
