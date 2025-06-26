
class Dua {
  final String id;
  final int manzilNumber;
  final String day;
  final int pageNumber;
  final String? source;
  final String arabicText;
  final Translations translations;
  final Faida faida;
  final String? audioUrl;
  final String? notes; // New field for notes/annotations

  Dua({
    required this.id,
    required this.manzilNumber,
    required this.day,
    required this.pageNumber,
    this.source,
    required this.arabicText,
    required this.translations,
    required this.faida,
    this.audioUrl,
    this.notes, // Initialize new field
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      manzilNumber: json['manzil_number'] as int,
      day: json['day'] as String,
      pageNumber: json['page_number'] as int,
      source: json['source'] as String?,
      arabicText: json['arabic_text'] as String,
      translations: Translations.fromJson(json['translations'] as Map<String, dynamic>),
      faida: Faida.fromJson(json['faida'] as Map<String, dynamic>),
      audioUrl: json['audio_url'] as String?,
      notes: json['notes'] as String?, // Deserialize new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manzil_number': manzilNumber,
      'day': day,
      'page_number': pageNumber,
      'source': source,
      'arabic_text': arabicText,
      'translations': translations.toJson(),
      'faida': faida.toJson(),
      'audio_url': audioUrl,
      'notes': notes, // Serialize new field
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dua &&
        other.id == id &&
        other.manzilNumber == manzilNumber &&
        other.day == day &&
        other.pageNumber == pageNumber &&
        other.source == source &&
        other.arabicText == arabicText &&
        other.translations == translations &&
        other.faida == faida &&
        other.audioUrl == audioUrl &&
        other.notes == notes; // Compare new field
  }

  @override
  int get hashCode => Object.hash(
        id,
        manzilNumber,
        day,
        pageNumber,
        source,
        arabicText,
        translations,
        faida,
        audioUrl,
        notes, // Include new field in hash code
      );
}

class Translations {
  final String urdu;
  final String english;
  final String burmese;

  Translations({
    required this.urdu,
    required this.english,
    required this.burmese,
  });

  factory Translations.fromJson(Map<String, dynamic> json) {
    return Translations(
      urdu: json['urdu'] as String,
      english: json['english'] as String,
      burmese: json['burmese'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urdu': urdu,
      'english': english,
      'burmese': burmese,
    };
  }

  String getTranslationText(String languageCode) {
    switch (languageCode) {
      case 'ur':
        return urdu;
      case 'en':
        return english;
      case 'my':
        return burmese;
      default:
        return english; // Fallback to English
    }
  }
}

class Faida {
  final String? urdu;
  final String? english;
  final String? burmese;

  Faida({
    this.urdu,
    this.english,
    this.burmese,
  });

  factory Faida.fromJson(Map<String, dynamic> json) {
    return Faida(
      urdu: json['urdu'] as String?,
      english: json['english'] as String?,
      burmese: json['burmese'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urdu': urdu,
      'english': english,
      'burmese': burmese,
    };
  }
}
