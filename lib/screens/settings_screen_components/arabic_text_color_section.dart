import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import 'settings_card.dart';
import 'color_selection_row.dart';

class ArabicTextColorSection extends StatelessWidget {
  final int arabicTextColorValue;
  final ValueChanged<Color> onColorChanged;

  const ArabicTextColorSection({
    super.key,
    required this.arabicTextColorValue,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppSettings appSettings = Provider.of<SettingsProvider>(context).appSettings;

    return SettingsCard(
      title: 'Arabic Text Color',
      icon: Icons.color_lens,
      children: [
        ColorSelectionRow(
          title: 'Choose color for Arabic text:',
          currentColor: Color(arabicTextColorValue),
          onColorChanged: onColorChanged,
        ),
      ],
    );
  }
}
