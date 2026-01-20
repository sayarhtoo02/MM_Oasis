import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';

class AppTheme {
  // --- Gradients ---
  // --- Gradients ---
  static const LinearGradient primaryGradientStyle = LinearGradient(
    colors: [
      Color(0xFF004D40), // Deep Teal
      Color(0xFF00695C), // Rich Teal
      Color(0xFF00796B), // Lighter Teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradientStyle = LinearGradient(
    colors: [
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA000), // Amber
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradientStyle = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradientStyle = LinearGradient(
    colors: [
      Color(0xFFF5F5F5), // White Smoke
      Color(0xFFE0F2F1), // Very Light Teal
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy support (can be deprecated later)
  static List<Color> primaryGradient(Color primaryColor) => [
    primaryColor,
    primaryColor.withValues(alpha: 0.85),
  ];

  static List<Color> goldGradient = [
    AppConstants.warmGoldAccent,
    AppConstants.warmGoldAccent.withValues(alpha: 0.8),
  ];

  static TextStyle get appBarTextStyle => const TextStyle(
    fontFamily: 'Poppins',
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static Color get appBarColor => Colors.transparent;
  static Color get appBarForegroundColor => Colors.white;

  static ThemeData lightTheme(
    BuildContext context,
    AppAccentColor accentColor,
  ) {
    final Color primaryColor =
        accentColor.color; // Use accent color from settings

    // Calculate tinted background for light mode
    final Color lightBackground = primaryColor.computeLuminance() > 0.9
        ? Colors.white
        : Color.alphaBlend(primaryColor.withValues(alpha: 0.05), Colors.white);

    return ThemeData(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: AppConstants.warmGoldAccent,
        onSecondary: Colors.black,
        surface: AppConstants.softCreamBackground,
        onSurface: Colors.black87,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Minimalist AppBar
        elevation: 0, // No shadow
        foregroundColor:
            Colors.white, // Use white for icons/text on dark background
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      buttonTheme: ButtonThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: AppConstants.warmGoldAccent,
        inactiveTrackColor: Colors.white24,
        thumbColor: AppConstants.warmGoldAccent,
        overlayColor: AppConstants.warmGoldAccent.withAlpha(
          (0.2 * 255).round(),
        ),
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.black,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.black87,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context, AppAccentColor accentColor) {
    final Color primaryColor =
        accentColor.color; // Use accent color from settings
    return ThemeData(
      scaffoldBackgroundColor: const Color(
        0xFF121212,
      ), // Standard dark mode background
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: AppConstants.warmGoldAccent,
        onSecondary: Colors.black,
        surface: const Color(0xFF1E1E1E), // Dark surface
        onSurface: const Color(0xFFE8E8E8), // Softer white
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: const Color(0xFFE8E8E8),
        displayColor: const Color(0xFFE8E8E8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Minimalist AppBar
        elevation: 0, // No shadow
        foregroundColor: Colors.white, // Use white for icons/text
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: const Color(0xFF2C2C2C),
        shadowColor: Colors.black.withValues(alpha: 0.4),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      buttonTheme: ButtonThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: AppConstants.warmGoldAccent,
        inactiveTrackColor: Colors.white24,
        thumbColor: AppConstants.warmGoldAccent,
        overlayColor: AppConstants.warmGoldAccent.withAlpha(
          (0.2 * 255).round(),
        ),
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.black,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFFE8E8E8),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
        ),
      ),
    );
  }
}
