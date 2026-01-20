class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      number: json['number'] ?? json['id'] ?? 0,
      name: json['name_arabic'] ?? json['name'] ?? '',
      englishName: json['name_simple'] ?? json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? json['name'] ?? '',
      numberOfAyahs: json['verses_count'] ?? json['numberOfAyahs'] ?? 0,
      revelationType: json['revelation_place'] ?? json['revelationType'] ?? '',
    );
  }

  factory QuranSurah.fromApi(Map<String, dynamic> json) {
    return QuranSurah(
      number: json['id'] ?? 0,
      name: json['name_arabic'] ?? '',
      englishName: json['name_simple'] ?? '',
      englishNameTranslation: json['translated_name']?['name'] ?? '',
      numberOfAyahs: json['verses_count'] ?? 0,
      revelationType: json['revelation_place'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name_arabic': name,
      'name_simple': englishName,
      'englishNameTranslation': englishNameTranslation,
      'verses_count': numberOfAyahs,
      'revelation_place': revelationType,
    };
  }
}
