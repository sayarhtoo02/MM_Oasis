class AllahName {
  final String arabic;
  final String english;
  final String urduMeaning;
  final String englishMeaning;
  final String englishExplanation;

  AllahName({
    required this.arabic,
    required this.english,
    required this.urduMeaning,
    required this.englishMeaning,
    required this.englishExplanation,
  });

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      arabic: json['arabic'] ?? '',
      english: json['english'] ?? '',
      urduMeaning: json['urduMeaning'] ?? '',
      englishMeaning: json['englishMeaning'] ?? '',
      englishExplanation: json['englishExplanation'] ?? '',
    );
  }
}
