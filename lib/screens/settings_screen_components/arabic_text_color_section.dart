import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_card.dart';
import 'color_option.dart'; // Import ColorOption

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SettingsCard(
      title: 'Arabic Text Color',
      icon: Icons.color_lens,
      children: [
        Text(
          'Choose color for Arabic text:',
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
              isSelected: Color(arabicTextColorValue) == Colors.black,
              onTap: () => onColorChanged(Colors.black),
            ),
            ColorOption(
              color: Colors.white,
              isSelected: Color(arabicTextColorValue) == Colors.white,
              onTap: () => onColorChanged(Colors.white),
            ),
            ColorOption(
              color: Colors.blue,
              isSelected: Color(arabicTextColorValue) == Colors.blue,
              onTap: () => onColorChanged(Colors.blue),
            ),
            ColorOption(
              color: Colors.red,
              isSelected: Color(arabicTextColorValue) == Colors.red,
              onTap: () => onColorChanged(Colors.red),
            ),
            ColorOption(
              color: Colors.green,
              isSelected: Color(arabicTextColorValue) == Colors.green,
              onTap: () => onColorChanged(Colors.green),
            ),
            ColorOption(
              color: Colors.purple,
              isSelected: Color(arabicTextColorValue) == Colors.purple,
              onTap: () => onColorChanged(Colors.purple),
            ),
            ColorOption(
              color: Colors.orange,
              isSelected: Color(arabicTextColorValue) == Colors.orange,
              onTap: () => onColorChanged(Colors.orange),
            ),
          ],
        ),
      ],
    );
  }
}
