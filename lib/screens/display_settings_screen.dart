import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../config/app_constants.dart'; // Import AppThemeMode and AppAccentColor
import '../screens/settings_screen_components/arabic_font_size_section.dart';
import '../screens/settings_screen_components/translation_font_size_section.dart';
import '../screens/settings_screen_components/theme_selection_section.dart';
import '../screens/settings_screen_components/color_selection_section.dart'; // New import

class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Display Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final appSettings = settingsProvider.appSettings;
          final displaySettings = appSettings.displaySettings;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.surface, colorScheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                ThemeSelectionSection(
                  selectedThemeMode: appSettings.themeMode,
                  onThemeModeChanged: (newValue) {
                    if (newValue != null) {
                      settingsProvider.setThemeMode(newValue);
                    }
                  },
                  translationFontSizeMultiplier: displaySettings.translationFontSizeMultiplier,
                ),
                const SizedBox(height: 20),
                ColorSelectionSection(
                  selectedColor: appSettings.accentColor,
                  onColorChanged: (newValue) {
                    if (newValue != null) {
                      settingsProvider.setAccentColor(newValue);
                    }
                  },
                ),
                const SizedBox(height: 20),
                ArabicFontSizeSection(
                  arabicFontSizeMultiplier: displaySettings.arabicFontSizeMultiplier,
                  translationFontSizeMultiplier: displaySettings.translationFontSizeMultiplier,
                  onChanged: (newValue) {
                    settingsProvider.setArabicFontSizeMultiplier(newValue);
                  },
                ),
                const SizedBox(height: 20),
                TranslationFontSizeSection(
                  translationFontSizeMultiplier: displaySettings.translationFontSizeMultiplier,
                  onChanged: (newValue) {
                    settingsProvider.setTranslationFontSizeMultiplier(newValue);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
