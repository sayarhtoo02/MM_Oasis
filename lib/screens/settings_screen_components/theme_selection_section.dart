import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_constants.dart';

import 'settings_card.dart';

class ThemeSelectionSection extends StatelessWidget {
  final AppThemeMode selectedThemeMode;
  final ValueChanged<AppThemeMode?> onThemeModeChanged;
  final double translationFontSizeMultiplier;

  const ThemeSelectionSection({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
    required this.translationFontSizeMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SettingsCard(
      title: 'Theme Selection',
      icon: Icons.brightness_6,
      children: [
        Text(
          'Choose your preferred theme:',
          style: GoogleFonts.poppins(
            fontSize: 16 * translationFontSizeMultiplier,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<AppThemeMode>(
          initialValue: selectedThemeMode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.7,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
          ),
          onChanged: onThemeModeChanged,
          items: const <DropdownMenuItem<AppThemeMode>>[
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.system,
              child: Text('System Default'),
            ),
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.light,
              child: Text('Light'),
            ),
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.dark,
              child: Text('Dark'),
            ),
          ],
          style: GoogleFonts.poppins(
            fontSize: 16 * translationFontSizeMultiplier,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          iconEnabledColor: colorScheme.primary,
        ),
      ],
    );
  }
}
