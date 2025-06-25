import 'package:flutter/material.dart';

class DisplaySettings {
  final double arabicFontSizeMultiplier;
  final double translationFontSizeMultiplier;
  final ThemeMode selectedThemeMode;

  DisplaySettings({
    required this.arabicFontSizeMultiplier,
    required this.translationFontSizeMultiplier,
    required this.selectedThemeMode,
  });

  DisplaySettings copyWith({
    double? arabicFontSizeMultiplier,
    double? translationFontSizeMultiplier,
    ThemeMode? selectedThemeMode,
  }) {
    return DisplaySettings(
      arabicFontSizeMultiplier: arabicFontSizeMultiplier ?? this.arabicFontSizeMultiplier,
      translationFontSizeMultiplier: translationFontSizeMultiplier ?? this.translationFontSizeMultiplier,
      selectedThemeMode: selectedThemeMode ?? this.selectedThemeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabicFontSizeMultiplier': arabicFontSizeMultiplier,
        'translationFontSizeMultiplier': translationFontSizeMultiplier,
        'selectedThemeMode': selectedThemeMode.index,
      };

  factory DisplaySettings.fromJson(Map<String, dynamic> json) => DisplaySettings(
        arabicFontSizeMultiplier: json['arabicFontSizeMultiplier'],
        translationFontSizeMultiplier: json['translationFontSizeMultiplier'],
        selectedThemeMode: ThemeMode.values[json['selectedThemeMode']],
      );

  static DisplaySettings initial() => DisplaySettings(
        arabicFontSizeMultiplier: 1.0,
        translationFontSizeMultiplier: 1.0,
        selectedThemeMode: ThemeMode.system,
      );
}
