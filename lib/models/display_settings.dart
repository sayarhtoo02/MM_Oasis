import 'package:flutter/material.dart';

class DisplaySettings {
  final double arabicFontSizeMultiplier;
  final double translationFontSizeMultiplier;
  final ThemeMode selectedThemeMode;
  final bool isReadingMode;
  final bool isNightReadingMode;
  final bool autoScrollEnabled;
  final double lineSpacing;

  DisplaySettings({
    required this.arabicFontSizeMultiplier,
    required this.translationFontSizeMultiplier,
    required this.selectedThemeMode,
    this.isReadingMode = false,
    this.isNightReadingMode = false,
    this.autoScrollEnabled = false,
    this.lineSpacing = 1.5,
  });

  DisplaySettings copyWith({
    double? arabicFontSizeMultiplier,
    double? translationFontSizeMultiplier,
    ThemeMode? selectedThemeMode,
    bool? isReadingMode,
    bool? isNightReadingMode,
    bool? autoScrollEnabled,
    double? lineSpacing,
  }) {
    return DisplaySettings(
      arabicFontSizeMultiplier: arabicFontSizeMultiplier ?? this.arabicFontSizeMultiplier,
      translationFontSizeMultiplier: translationFontSizeMultiplier ?? this.translationFontSizeMultiplier,
      selectedThemeMode: selectedThemeMode ?? this.selectedThemeMode,
      isReadingMode: isReadingMode ?? this.isReadingMode,
      isNightReadingMode: isNightReadingMode ?? this.isNightReadingMode,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      lineSpacing: lineSpacing ?? this.lineSpacing,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabicFontSizeMultiplier': arabicFontSizeMultiplier,
        'translationFontSizeMultiplier': translationFontSizeMultiplier,
        'selectedThemeMode': selectedThemeMode.index,
        'isReadingMode': isReadingMode,
        'isNightReadingMode': isNightReadingMode,
        'autoScrollEnabled': autoScrollEnabled,
        'lineSpacing': lineSpacing,
      };

  factory DisplaySettings.fromJson(Map<String, dynamic> json) => DisplaySettings(
        arabicFontSizeMultiplier: json['arabicFontSizeMultiplier'],
        translationFontSizeMultiplier: json['translationFontSizeMultiplier'],
        selectedThemeMode: ThemeMode.values[json['selectedThemeMode']],
        isReadingMode: json['isReadingMode'] ?? false,
        isNightReadingMode: json['isNightReadingMode'] ?? false,
        autoScrollEnabled: json['autoScrollEnabled'] ?? false,
        lineSpacing: json['lineSpacing'] ?? 1.5,
      );

  static DisplaySettings initial() => DisplaySettings(
        arabicFontSizeMultiplier: 1.0,
        translationFontSizeMultiplier: 1.0,
        selectedThemeMode: ThemeMode.system,
      );
}
