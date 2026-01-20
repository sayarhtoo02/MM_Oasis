import 'package:flutter/material.dart';

class GlassTheme {
  // Light Mode Colors
  static const Color lightBackground = Colors.white;
  static const Color lightText = Color(0xFF0D3B2E); // Dark Teal
  static const Color lightAccent = Color(0xFFE0B40A); // Gold
  static const Color lightGlassStart = Color(0xCCFFFFFF); // White 0.8
  static const Color lightGlassEnd = Color(0x4DFFFFFF); // White 0.3
  static const Color lightBorder = Color(0x99FFFFFF); // White 0.6
  static const Color lightShadow = Color(0x260D3B2E); // Teal 0.15

  // Dark Mode Colors
  static const Color darkBackground = Colors.black;
  static const Color darkText = Colors.white;
  static const Color darkAccent = Color(0xFFE0B40A); // Gold
  static const Color darkGlassStart = Color(0x1AFFFFFF); // White 0.1
  static const Color darkGlassEnd = Color(0x0DFFFFFF); // White 0.05
  static const Color darkBorder = Color(0x33FFFFFF); // White 0.2
  static const Color darkShadow = Color(0x4D000000); // Black 0.3

  static Color? _currentAccent;

  static void setAccent(Color color) {
    _currentAccent = color;
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(bool isDark) {
    if (isDark) return darkBackground;

    // Tint background with accent color in light mode
    if (_currentAccent != null) {
      if (_currentAccent!.computeLuminance() > 0.9) {
        return Colors.white; // Keep pure white for very light accents
      }
      return Color.alphaBlend(
        _currentAccent!.withValues(alpha: 0.05),
        Colors.white,
      );
    }
    return lightBackground;
  }

  static Color text(bool isDark) => isDark ? darkText : lightText;

  static Color accent(bool isDark) {
    if (_currentAccent != null) return _currentAccent!;
    return isDark ? darkAccent : lightAccent;
  }

  static List<Color> glassGradient(bool isDark) {
    return isDark
        ? [darkGlassStart, darkGlassEnd]
        : [lightGlassStart, lightGlassEnd];
  }

  static Color glassBorder(bool isDark) => isDark ? darkBorder : lightBorder;

  static List<BoxShadow> glassShadow(bool isDark) {
    return [
      BoxShadow(
        color: isDark ? darkShadow : lightShadow,
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
