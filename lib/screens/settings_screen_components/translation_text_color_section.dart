import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'settings_card.dart';
import 'color_option.dart'; // Import ColorOption

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SettingsCard(
      title: 'Translation Text Color',
      icon: Icons.color_lens,
      children: [
        Text(
          'Choose color for translation text:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ColorOption(
              color: Colors.black,
              isSelected: Color(translationTextColorValue) == Colors.black,
              onTap: () => onColorChanged(Colors.black),
            ),
            ColorOption(
              color: Colors.white,
              isSelected: Color(translationTextColorValue) == Colors.white,
              onTap: () => onColorChanged(Colors.white),
            ),
            ColorOption(
              color: Colors.blue,
              isSelected: Color(translationTextColorValue) == Colors.blue,
              onTap: () => onColorChanged(Colors.blue),
            ),
            ColorOption(
              color: Colors.red,
              isSelected: Color(translationTextColorValue) == Colors.red,
              onTap: () => onColorChanged(Colors.red),
            ),
            ColorOption(
              color: Colors.green,
              isSelected: Color(translationTextColorValue) == Colors.green,
              onTap: () => onColorChanged(Colors.green),
            ),
            ColorOption(
              color: Colors.purple,
              isSelected: Color(translationTextColorValue) == Colors.purple,
              onTap: () => onColorChanged(Colors.purple),
            ),
            ColorOption(
              color: Colors.orange,
              isSelected: Color(translationTextColorValue) == Colors.orange,
              onTap: () => onColorChanged(Colors.orange),
            ),
          ],
        ),
      ],
    );
  }
}
