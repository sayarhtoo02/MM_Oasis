import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

class AppConstants {
  static const String customCollectionDetailRoute = '/custom-collection-detail';

  // Enhanced Color Palette
  static const Color primaryDeepGreen = Color(
    0xFF1B4D3E,
  ); // Deep, rich green for background
  static const Color warmGoldAccent = Color(0xFFFFB300);
  static const Color softCreamBackground = Color(0xFFFFF8E1);
}

enum AppAccentColor {
  white, // New Default
  islamicGreen,
  emerald,
  teal,
  blue,
  skyBlue,
  indigo,
  purple,
  rose,
  orange,
  amber,
}

extension AppAccentColorExtension on AppAccentColor {
  Color get color {
    switch (this) {
      case AppAccentColor.white:
        return const Color(
          0xFFF5F5F5,
        ); // Slightly off-white for visibility against white bg
      case AppAccentColor.islamicGreen:
        return const Color(0xFF1B4D3E);
      case AppAccentColor.emerald:
        return const Color(0xFF2E7D32);
      case AppAccentColor.teal:
        return const Color(0xFF009688);
      case AppAccentColor.blue:
        return const Color(0xFF1565C0);
      case AppAccentColor.skyBlue:
        return const Color(0xFF4FC3F7); // Light Blue
      case AppAccentColor.indigo:
        return const Color(0xFF3F51B5);
      case AppAccentColor.purple:
        return const Color(0xFF6A1B9A);
      case AppAccentColor.rose:
        return const Color(0xFFE91E63);
      case AppAccentColor.orange:
        return const Color(0xFFEF6C00);
      case AppAccentColor.amber:
        return const Color(0xFFFFB300);
    }
  }

  String get displayName {
    switch (this) {
      case AppAccentColor.white:
        return 'White (Default)';
      case AppAccentColor.islamicGreen:
        return 'Islamic Green';
      case AppAccentColor.emerald:
        return 'Emerald';
      case AppAccentColor.teal:
        return 'Teal';
      case AppAccentColor.blue:
        return 'Blue';
      case AppAccentColor.skyBlue:
        return 'Sky Blue';
      case AppAccentColor.indigo:
        return 'Indigo';
      case AppAccentColor.purple:
        return 'Purple';
      case AppAccentColor.rose:
        return 'Rose';
      case AppAccentColor.orange:
        return 'Orange';
      case AppAccentColor.amber:
        return 'Amber';
    }
  }
}
