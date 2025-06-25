import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import 'settings_card.dart';
import 'color_selection_row.dart';

class TranslationTextColorSection extends StatelessWidget {
  final int translationTextColorValue;
  final ValueChanged<Color> onColorChanged;

  const TranslationTextColorSection({
    super.key,
    required this.translationTextColorValue,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppSettings appSettings = Provider.of<SettingsProvider>(context).appSettings;

    return SettingsCard(
      title: 'Translation Text Color',
      icon: Icons.color_lens,
      children: [
        ColorSelectionRow(
          title: 'Choose color for translation text:',
          currentColor: Color(translationTextColorValue),
          onColorChanged: onColorChanged,
        ),
      ],
    );
  }
}
