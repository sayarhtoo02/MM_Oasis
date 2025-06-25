import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../models/display_settings.dart'; // Import DisplaySettings directly
import '../screens/settings_screen_components/arabic_font_size_section.dart';
import '../screens/settings_screen_components/translation_font_size_section.dart';
import '../screens/settings_screen_components/theme_selection_section.dart';

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
      body: Selector<SettingsProvider, DisplaySettings>(
        selector: (context, provider) => provider.appSettings.displaySettings,
        builder: (context, displaySettings, child) {
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
                  selectedThemeMode: displaySettings.selectedThemeMode,
                  onThemeModeChanged: (newValue) {
                    if (newValue != null) {
                      settingsProvider.setSelectedThemeMode(newValue);
                    }
                  },
                  translationFontSizeMultiplier: displaySettings.translationFontSizeMultiplier,
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
