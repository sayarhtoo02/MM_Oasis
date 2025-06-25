import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_option.dart';

class ColorSelectionRow extends StatelessWidget {
  final String title;
  final Color currentColor;
  final Function(Color) onColorChanged;

  const ColorSelectionRow({
    super.key,
    required this.title,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
            ColorOption(color: Colors.black, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.white, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.blue, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.red, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.green, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.purple, currentColor: currentColor, onColorChanged: onColorChanged),
            ColorOption(color: Colors.orange, currentColor: currentColor, onColorChanged: onColorChanged),
          ],
        ),
      ],
    );
  }
}
