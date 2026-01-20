class QuranAyah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final String? translation;
  final Map<String, String>? translations;

  QuranAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    this.translation,
    this.translations,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> json) {
    return QuranAyah(
      number: json['number'] ?? json['id'] ?? 0,
      text: json['text'] ?? json['text_uthmani'] ?? '',
      numberInSurah: json['numberInSurah'] ?? json['ayah_number'] ?? 0,
      juz: json['juz'] ?? json['juz_number'] ?? 0,
      manzil: json['manzil'] ?? json['manzil_number'] ?? 0,
      page: json['page'] ?? json['page_number'] ?? 0,
      ruku: json['ruku'] ?? json['ruku_number'] ?? 0,
      hizbQuarter: json['hizbQuarter'] ?? json['hizb_number'] ?? 0,
      translation: json['translation'],
    );
  }

  factory QuranAyah.fromApi(Map<String, dynamic> json) {
    return QuranAyah(
      number: json['verse_number'] ?? json['id'] ?? 0,
      text: json['text_uthmani'] ?? json['text'] ?? '',
      numberInSurah: json['number_in_surah'] ?? json['verse_number'] ?? 0,
      juz: json['juz_number'] ?? 0,
      manzil: json['manzil_number'] ?? 0,
      page: json['page_number'] ?? 0,
      ruku: json['ruku_number'] ?? 0,
      hizbQuarter: json['hizb_number'] ?? 0,
      translation: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
    };
  }

  QuranAyah copyWith({String? translation, Map<String, String>? translations}) {
    return QuranAyah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      manzil: manzil,
      page: page,
      ruku: ruku,
      hizbQuarter: hizbQuarter,
      translation: translation ?? this.translation,
      translations: translations ?? this.translations,
    );
  }
}
