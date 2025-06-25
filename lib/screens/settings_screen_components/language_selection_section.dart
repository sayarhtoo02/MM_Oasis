import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import 'settings_card.dart';

class LanguageSelectionSection extends StatelessWidget {
  const LanguageSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSettings appSettings = Provider.of<SettingsProvider>(context).appSettings;

    return SettingsCard(
      title: 'Language Selection',
      icon: Icons.language,
      children: [
        Text(
          'Choose your preferred language:',
          style: GoogleFonts.poppins(
            fontSize: 16 * appSettings.displaySettings.translationFontSizeMultiplier,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: appSettings.languageSettings.selectedLanguage,
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
              Provider.of<SettingsProvider>(context, listen: false).setSelectedLanguage(newValue);
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
            fontSize: 16 * appSettings.displaySettings.translationFontSizeMultiplier,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          iconEnabledColor: colorScheme.primary,
        ),
      ],
    );
  }
}