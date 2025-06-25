class LanguageSettings {
  final String selectedLanguage;

  LanguageSettings({required this.selectedLanguage});

  LanguageSettings copyWith({String? selectedLanguage}) {
    return LanguageSettings(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedLanguage': selectedLanguage,
      };

  factory LanguageSettings.fromJson(Map<String, dynamic> json) => LanguageSettings(
        selectedLanguage: json['selectedLanguage'],
      );

  static LanguageSettings initial() => LanguageSettings(selectedLanguage: 'my');
}
