import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';

class AppTheme {
  static const Color _secondaryAccent = Color(0xFFBCAAA4); // Muted grey-brown/cream

  static TextStyle get appBarTextStyle => GoogleFonts.poppins(
        color: AppAccentColor.green.color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  static Color get appBarColor => Colors.transparent;
  static Color get appBarForegroundColor => AppAccentColor.green.color;

  static ThemeData lightTheme(BuildContext context, AppAccentColor accentColor) {
    final Color primaryColor = accentColor.color;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: _secondaryAccent,
        onSecondary: Colors.black,
        surface: const Color(0xFFF5F5F5), // Light grey for background
        onSurface: Colors.black87,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme,
      ).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Minimalist AppBar
        elevation: 0, // No shadow
        foregroundColor: primaryColor, // Use primary color for icons/text
        titleTextStyle: GoogleFonts.poppins(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 8, // More refined shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), // Slightly larger rounded corners
        ),
        color: Color(0xFFFFFFFF), // White cards
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withAlpha((0.3 * 255).round()),
        thumbColor: _secondaryAccent,
        overlayColor: _secondaryAccent.withAlpha((0.2 * 255).round()),
        valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.poppins(color: Colors.black87),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context, AppAccentColor accentColor) {
    final Color primaryColor = accentColor.color;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: _secondaryAccent,
        onSecondary: Colors.black,
        surface: const Color(0xFF121212), // Even deeper dark grey for background
        onSurface: Colors.white70,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme,
      ).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Minimalist AppBar
        elevation: 0, // No shadow
        foregroundColor: _secondaryAccent, // Use secondary color for icons/text
        titleTextStyle: GoogleFonts.poppins(
          color: _secondaryAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 8, // More refined shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), // Slightly larger rounded corners
        ),
        color: Color(0xFF1E1E1E), // Slightly lighter dark grey cards
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withAlpha((0.3 * 255).round()),
        thumbColor: _secondaryAccent,
        overlayColor: _secondaryAccent.withAlpha((0.2 * 255).round()),
        valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.poppins(color: Colors.white70),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
        ),
      ),
    );
  }
}
