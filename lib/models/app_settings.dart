import 'package:munajat_e_maqbool_app/models/display_settings.dart';
import 'package:munajat_e_maqbool_app/models/language_settings.dart';
import 'package:munajat_e_maqbool_app/models/dua_preferences.dart';

class AppSettings {
  final DisplaySettings displaySettings;
  final LanguageSettings languageSettings;
  final DuaPreferences duaPreferences;
  // Add more setting categories as needed

  AppSettings({
    required this.displaySettings,
    required this.languageSettings,
    required this.duaPreferences,
  });

  AppSettings copyWith({
    DisplaySettings? displaySettings,
    LanguageSettings? languageSettings,
    DuaPreferences? duaPreferences,
  }) {
    return AppSettings(
      displaySettings: displaySettings ?? this.displaySettings,
      languageSettings: languageSettings ?? this.languageSettings,
      duaPreferences: duaPreferences ?? this.duaPreferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'displaySettings': displaySettings.toJson(),
        'languageSettings': languageSettings.toJson(),
        'duaPreferences': duaPreferences.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        displaySettings: DisplaySettings.fromJson(json['displaySettings']),
        languageSettings: LanguageSettings.fromJson(json['languageSettings']),
        duaPreferences: DuaPreferences.fromJson(json['duaPreferences']),
      );

  // Default settings
  static AppSettings initial() => AppSettings(
        displaySettings: DisplaySettings.initial(),
        languageSettings: LanguageSettings.initial(),
        duaPreferences: DuaPreferences.initial(),
      );
}