import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dua_model.dart';
import '../../providers/settings_provider.dart';

class DuaContentDisplay extends StatelessWidget {
  final Dua dua;
  final String selectedLanguage;

  const DuaContentDisplay({
    super.key,
    required this.dua,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withValues(alpha: 0.05), // Softer shadow
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(24.0), // Rounded corners
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dua.arabicText,
            textAlign: TextAlign.center, // Center align for better aesthetics
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Indopak',
              letterSpacing: 0,
              fontSize:
                  38 *
                  settingsProvider
                      .appSettings
                      .displaySettings
                      .arabicFontSizeMultiplier,
              height: 2.3, // Increased line height
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            thickness: 1,
            indent: 40,
            endIndent: 40,
          ),
          const SizedBox(height: 20),
          Text(
            dua.translations.getTranslationText(selectedLanguage),
            style: TextStyle(
              fontSize:
                  18 *
                  settingsProvider
                      .appSettings
                      .displaySettings
                      .translationFontSizeMultiplier,
              fontFamily: selectedLanguage == 'mm' ? 'Myanmar' : 'Roboto',
              height: 1.6, // Improved readability
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
          if (dua.source != null && dua.source!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Source: ${dua.source}',
              style: TextStyle(
                fontSize:
                    14 *
                    settingsProvider
                        .appSettings
                        .displaySettings
                        .translationFontSizeMultiplier,
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
