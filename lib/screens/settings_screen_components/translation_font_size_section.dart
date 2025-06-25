import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import 'settings_card.dart';

class TranslationFontSizeSection extends StatelessWidget {
  final double translationFontSizeMultiplier;
  final ValueChanged<double> onChanged;

  const TranslationFontSizeSection({
    super.key,
    required this.translationFontSizeMultiplier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSettings appSettings = Provider.of<SettingsProvider>(context).appSettings;

    return SettingsCard(
      title: 'Translation Font Size Adjustment',
      icon: Icons.format_size,
      children: [
        Text(
          'Adjust the translation text size:',
          style: GoogleFonts.poppins(
            fontSize: 16 * translationFontSizeMultiplier,
            color: colorScheme.onSurface,
          ),
        ),
        FlutterSlider(
          values: [translationFontSizeMultiplier],
          min: 0.8,
          max: 1.5,
          step: const FlutterSliderStep(step: 0.1),
          tooltip: FlutterSliderTooltip(
            format: (value) => '${double.parse(value).toStringAsFixed(1)}x',
            textStyle: GoogleFonts.poppins(color: Colors.white),
            boxStyle: FlutterSliderTooltipBox(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          handler: FlutterSliderHandler(
            decoration: const BoxDecoration(),
            child: Material(
              type: MaterialType.canvas,
              color: colorScheme.secondary,
              elevation: 3,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.circle,
                  color: colorScheme.onSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          rightHandler: FlutterSliderHandler(
            decoration: const BoxDecoration(),
            child: Material(
              type: MaterialType.canvas,
              color: colorScheme.secondary,
              elevation: 3,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.circle,
                  color: colorScheme.onSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          trackBar: FlutterSliderTrackBar(
            activeTrackBarHeight: 8,
            inactiveTrackBarHeight: 8,
            activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: colorScheme.primary,
            ),
            inactiveTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
          ),
          onDragging: (handlerIndex, lowerValue, upperValue) {
            onChanged(lowerValue);
          },
          onDragCompleted: (handlerIndex, lowerValue, upperValue) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Translation font size set to ${lowerValue.toStringAsFixed(1)}x',
                  style: GoogleFonts.poppins(color: colorScheme.onPrimary),
                ),
                backgroundColor: colorScheme.primary,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        Text(
          'Preview Text: "The quick brown fox jumps over the lazy dog."',
          style: GoogleFonts.poppins(
            fontSize: 16 * translationFontSizeMultiplier,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
