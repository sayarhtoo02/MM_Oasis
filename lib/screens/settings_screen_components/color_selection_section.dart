import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen_components/color_option.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen_components/settings_card.dart';

class ColorSelectionSection extends StatelessWidget {
  final AppAccentColor selectedColor;
  final ValueChanged<AppAccentColor?> onColorChanged;

  const ColorSelectionSection({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppAccentColor.values.map((colorOption) {
              return ColorOption(
                color: colorOption.color,
                isSelected: selectedColor == colorOption,
                onTap: () => onColorChanged(colorOption),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
