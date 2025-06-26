import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

class AppConstants {
  static const String customCollectionDetailRoute = '/custom-collection-detail';
}

enum AppAccentColor {
  green,
  blue,
  purple,
  orange,
}

extension AppAccentColorExtension on AppAccentColor {
  Color get color {
    switch (this) {
      case AppAccentColor.green:
        return const Color(0xFF2E7D32); // Deeper, calming green
      case AppAccentColor.blue:
        return const Color(0xFF1976D2); // Standard Blue
      case AppAccentColor.purple:
        return const Color(0xFF6A1B9A); // Deep Purple
      case AppAccentColor.orange:
        return const Color(0xFFEF6C00); // Deep Orange
    }
  }

  String get name {
    switch (this) {
      case AppAccentColor.green:
        return 'Green';
      case AppAccentColor.blue:
        return 'Blue';
      case AppAccentColor.purple:
        return 'Purple';
      case AppAccentColor.orange:
        return 'Orange';
    }
  }
}
