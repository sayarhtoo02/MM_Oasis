import 'package:munajat_e_maqbool_app/models/display_settings.dart';
import 'package:munajat_e_maqbool_app/models/language_settings.dart';
import 'package:munajat_e_maqbool_app/models/dua_preferences.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';

class AppSettings {
  final DisplaySettings displaySettings;
  final LanguageSettings languageSettings;
  final DuaPreferences duaPreferences;
  final int? reminderHour;
  final int? reminderMinute;
  final bool isReminderEnabled;
  final AppThemeMode themeMode; // New: for theme mode
  final AppAccentColor accentColor; // New: for accent color

  AppSettings({
    required this.displaySettings,
    required this.languageSettings,
    required this.duaPreferences,
    this.reminderHour,
    this.reminderMinute,
    this.isReminderEnabled = false,
    this.themeMode = AppThemeMode.system, // Add to constructor with default
    this.accentColor = AppAccentColor.green, // Add to constructor with default
  });

  AppSettings copyWith({
    DisplaySettings? displaySettings,
    LanguageSettings? languageSettings,
    DuaPreferences? duaPreferences,
    int? reminderHour,
    int? reminderMinute,
    bool? isReminderEnabled,
    AppThemeMode? themeMode, // Add to copyWith
    AppAccentColor? accentColor, // Add to copyWith
  }) {
    return AppSettings(
      displaySettings: displaySettings ?? this.displaySettings,
      languageSettings: languageSettings ?? this.languageSettings,
      duaPreferences: duaPreferences ?? this.duaPreferences,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      themeMode: themeMode ?? this.themeMode, // Copy new fields
      accentColor: accentColor ?? this.accentColor, // Copy new fields
    );
  }

  Map<String, dynamic> toJson() => {
        'displaySettings': displaySettings.toJson(),
        'languageSettings': languageSettings.toJson(),
        'duaPreferences': duaPreferences.toJson(),
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'isReminderEnabled': isReminderEnabled,
        'themeMode': themeMode.name, // Add to toJson
        'accentColor': accentColor.name, // Add to toJson
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        displaySettings: DisplaySettings.fromJson(json['displaySettings']),
        languageSettings: LanguageSettings.fromJson(json['languageSettings']),
        duaPreferences: DuaPreferences.fromJson(json['duaPreferences']),
        reminderHour: json['reminderHour'] as int?,
        reminderMinute: json['reminderMinute'] as int?,
        isReminderEnabled: json['isReminderEnabled'] as bool? ?? false,
        themeMode: AppThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ), // Parse new fields
        accentColor: AppAccentColor.values.firstWhere(
          (e) => e.name == json['accentColor'],
          orElse: () => AppAccentColor.green,
        ), // Parse new fields
      );

  // Default settings
  static AppSettings initial() => AppSettings(
        displaySettings: DisplaySettings.initial(),
        languageSettings: LanguageSettings.initial(),
        duaPreferences: DuaPreferences.initial(),
        reminderHour: null,
        reminderMinute: null,
        isReminderEnabled: false,
        themeMode: AppThemeMode.system, // Initialize new fields
        accentColor: AppAccentColor.green, // Initialize new fields
      );
}
