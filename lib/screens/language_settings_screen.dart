import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../models/language_settings.dart'; // Import LanguageSettings
import '../screens/settings_screen_components/settings_card.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Language Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Selector<SettingsProvider, LanguageSettings>(
        selector: (context, provider) => provider.appSettings.languageSettings,
        builder: (context, languageSettings, child) {
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
                SettingsCard(
                  title: 'Language Selection',
                  icon: Icons.language,
                  children: [
                    Text(
                      'Choose your preferred language:',
                      style: GoogleFonts.poppins(
                        fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: languageSettings.selectedLanguage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary.withAlpha((0.5 * 255).round())),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary.withAlpha((0.5 * 255).round())),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withAlpha((0.7 * 255).round()),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          settingsProvider.setSelectedLanguage(newValue);
                        }
                      },
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'my',
                          child: Text('Burmese'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ur',
                          child: Text('Urdu'),
                        ),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                        color: colorScheme.onSurface,
                      ),
                      dropdownColor: colorScheme.surface,
                      iconEnabledColor: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
