import 'package:munajat_e_maqbool_app/models/display_settings.dart';
import 'package:munajat_e_maqbool_app/models/language_settings.dart';
import 'package:munajat_e_maqbool_app/models/dua_preferences.dart';
import 'package:munajat_e_maqbool_app/models/reminder_settings.dart';
import 'package:munajat_e_maqbool_app/models/widget_settings.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';

class AppSettings {
  final DisplaySettings displaySettings;
  final LanguageSettings languageSettings;
  final DuaPreferences duaPreferences;
  final int? reminderHour;
  final int? reminderMinute;
  final bool isReminderEnabled;
  final List<ReminderSchedule> reminderSchedules;
  final NotificationPreferences notificationPreferences;
  final WidgetSettings widgetSettings;
  final AppThemeMode themeMode; // New: for theme mode
  final AppAccentColor accentColor; // New: for accent color
  final double? prayerLatitude;
  final double? prayerLongitude;
  final String? prayerCity;
  final String? prayerCalculationMethod;
  final String? prayerAsrMethod;

  AppSettings({
    required this.displaySettings,
    required this.languageSettings,
    required this.duaPreferences,
    this.reminderHour,
    this.reminderMinute,
    this.isReminderEnabled = false,
    this.reminderSchedules = const [],
    required this.notificationPreferences,
    required this.widgetSettings,
    this.themeMode = AppThemeMode.system, // Add to constructor with default
    this.accentColor = AppAccentColor.white, // White as default
    this.prayerLatitude,
    this.prayerLongitude,
    this.prayerCity,
    this.prayerCalculationMethod,
    this.prayerAsrMethod,
  });

  AppSettings copyWith({
    DisplaySettings? displaySettings,
    LanguageSettings? languageSettings,
    DuaPreferences? duaPreferences,
    int? reminderHour,
    int? reminderMinute,
    bool? isReminderEnabled,
    List<ReminderSchedule>? reminderSchedules,
    NotificationPreferences? notificationPreferences,
    WidgetSettings? widgetSettings,
    AppThemeMode? themeMode, // Add to copyWith
    AppAccentColor? accentColor, // Add to copyWith
    double? prayerLatitude,
    double? prayerLongitude,
    String? prayerCity,
    String? prayerCalculationMethod,
    String? prayerAsrMethod,
  }) {
    return AppSettings(
      displaySettings: displaySettings ?? this.displaySettings,
      languageSettings: languageSettings ?? this.languageSettings,
      duaPreferences: duaPreferences ?? this.duaPreferences,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderSchedules: reminderSchedules ?? this.reminderSchedules,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      widgetSettings: widgetSettings ?? this.widgetSettings,
      themeMode: themeMode ?? this.themeMode, // Copy new fields
      accentColor: accentColor ?? this.accentColor, // Copy new fields
      prayerLatitude: prayerLatitude ?? this.prayerLatitude,
      prayerLongitude: prayerLongitude ?? this.prayerLongitude,
      prayerCity: prayerCity ?? this.prayerCity,
      prayerCalculationMethod:
          prayerCalculationMethod ?? this.prayerCalculationMethod,
      prayerAsrMethod: prayerAsrMethod ?? this.prayerAsrMethod,
    );
  }

  Map<String, dynamic> toJson() => {
    'displaySettings': displaySettings.toJson(),
    'languageSettings': languageSettings.toJson(),
    'duaPreferences': duaPreferences.toJson(),
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'isReminderEnabled': isReminderEnabled,
    'reminderSchedules': reminderSchedules.map((r) => r.toJson()).toList(),
    'notificationPreferences': notificationPreferences.toJson(),
    'widgetSettings': widgetSettings.toJson(),
    'themeMode': themeMode.name, // Add to toJson
    'accentColor': accentColor.name, // Add to toJson
    'prayerLatitude': prayerLatitude,
    'prayerLongitude': prayerLongitude,
    'prayerCity': prayerCity,
    'prayerCalculationMethod': prayerCalculationMethod,
    'prayerAsrMethod': prayerAsrMethod,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    displaySettings: DisplaySettings.fromJson(json['displaySettings']),
    languageSettings: LanguageSettings.fromJson(json['languageSettings']),
    duaPreferences: DuaPreferences.fromJson(json['duaPreferences']),
    reminderHour: json['reminderHour'] as int?,
    reminderMinute: json['reminderMinute'] as int?,
    isReminderEnabled: json['isReminderEnabled'] as bool? ?? false,
    reminderSchedules:
        (json['reminderSchedules'] as List<dynamic>?)
            ?.map((r) => ReminderSchedule.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [],
    notificationPreferences: json['notificationPreferences'] != null
        ? NotificationPreferences.fromJson(json['notificationPreferences'])
        : NotificationPreferences.initial(),
    widgetSettings: json['widgetSettings'] != null
        ? WidgetSettings.fromJson(json['widgetSettings'])
        : WidgetSettings.initial(),
    themeMode: AppThemeMode.values.firstWhere(
      (e) => e.name == json['themeMode'],
      orElse: () => AppThemeMode.system,
    ), // Parse new fields
    accentColor: AppAccentColor.values.firstWhere(
      (e) => e.name == json['accentColor'],
      orElse: () => AppAccentColor.white, // White as fallback
    ), // Parse new fields
    prayerLatitude: json['prayerLatitude'] as double?,
    prayerLongitude: json['prayerLongitude'] as double?,
    prayerCity: json['prayerCity'] as String?,
    prayerCalculationMethod: json['prayerCalculationMethod'] as String?,
    prayerAsrMethod: json['prayerAsrMethod'] as String?,
  );

  // Default settings
  static AppSettings initial() => AppSettings(
    displaySettings: DisplaySettings.initial(),
    languageSettings: LanguageSettings.initial(),
    duaPreferences: DuaPreferences.initial(),
    reminderHour: null,
    reminderMinute: null,
    isReminderEnabled: false,
    reminderSchedules: const [],
    notificationPreferences: NotificationPreferences.initial(),
    widgetSettings: WidgetSettings.initial(),
    themeMode: AppThemeMode.system, // Initialize new fields
    accentColor: AppAccentColor.islamicGreen, // White as default
    prayerLatitude: 21.4225,
    prayerLongitude: 96.0836,
    prayerCity: 'Yangon, Myanmar',
    prayerCalculationMethod: 'karachi',
    prayerAsrMethod: 'hanafi',
  );
}
