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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dua.arabicText,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Arabic',
              fontSize: 38 * settingsProvider.appSettings.displaySettings.arabicFontSizeMultiplier,
              height: 2.0,
              letterSpacing: 0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            dua.translations.getTranslationText(selectedLanguage),
            style: TextStyle(
              fontSize: 18 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
              fontFamily: selectedLanguage == 'my' ? 'Myanmar' : 'Roboto',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 25),
          Text(
            'Source: ${dua.source}',
            style: TextStyle(
              fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
