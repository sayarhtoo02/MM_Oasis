import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../config/app_constants.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../utils/haptic_feedback_helper.dart';
import '../models/app_settings.dart';
import '../models/display_settings.dart';

class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final appSettings = settingsProvider.appSettings;
        final displaySettings = appSettings.displaySettings;

        return GlassScaffold(
          title: 'Display & Theme',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeSection(
                context,
                settingsProvider,
                appSettings,
                isDark,
                textColor,
                accentColor,
              ),
              const SizedBox(height: 16),
              _buildColorSection(
                context,
                settingsProvider,
                appSettings,
                isDark,
                textColor,
                accentColor,
              ),
              const SizedBox(height: 16),
              _buildFontSection(
                context,
                settingsProvider,
                displaySettings,
                isDark,
                textColor,
                accentColor,
              ),
              const SizedBox(height: 16),
              _buildReadingModeSection(
                context,
                settingsProvider,
                displaySettings,
                isDark,
                textColor,
                accentColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Theme Mode',
            Icons.brightness_6,
            textColor,
            accentColor,
          ),
          const SizedBox(height: 16),
          ...AppThemeMode.values.map(
            (mode) => _buildRadioTile(
              context,
              title: mode.name.toUpperCase(),
              value: mode,
              groupValue: settings.themeMode,
              isDark: isDark,
              textColor: textColor,
              accentColor: accentColor,
              onChanged: (value) {
                HapticFeedbackHelper.selectionClick();
                provider.setThemeMode(value as AppThemeMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(
    BuildContext context,
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Accent Color',
            Icons.palette,
            textColor,
            accentColor,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: AppAccentColor.values
                .map(
                  (color) => _buildColorOption(
                    context,
                    color: color.color,
                    isSelected: settings.accentColor == color,
                    onTap: () {
                      HapticFeedbackHelper.selectionClick();
                      provider.setAccentColor(color);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSection(
    BuildContext context,
    SettingsProvider provider,
    DisplaySettings settings,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Font Sizes',
            Icons.text_fields,
            textColor,
            accentColor,
          ),
          const SizedBox(height: 16),
          _buildSliderTile(
            context,
            title: 'Arabic Text',
            value: settings.arabicFontSizeMultiplier,
            min: 0.8,
            max: 2.0,
            textColor: textColor,
            accentColor: accentColor,
            onChanged: (value) => provider.setArabicFontSizeMultiplier(value),
          ),
          const SizedBox(height: 16),
          _buildSliderTile(
            context,
            title: 'Translation Text',
            value: settings.translationFontSizeMultiplier,
            min: 0.8,
            max: 2.0,
            textColor: textColor,
            accentColor: accentColor,
            onChanged: (value) =>
                provider.setTranslationFontSizeMultiplier(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingModeSection(
    BuildContext context,
    SettingsProvider provider,
    DisplaySettings settings,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Reading Experience',
            Icons.auto_stories,
            textColor,
            accentColor,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            title: 'Night Reading Mode',
            subtitle: 'Amber text for comfortable night reading',
            value: settings.isNightReadingMode,
            textColor: textColor,
            accentColor: accentColor,
            onChanged: (value) => provider.setNightReadingMode(value),
          ),
          _buildSwitchTile(
            context,
            title: 'Auto Scroll',
            subtitle: 'Automatically scroll during audio playback',
            value: settings.autoScrollEnabled,
            textColor: textColor,
            accentColor: accentColor,
            onChanged: (value) => provider.setAutoScrollEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color textColor,
    Color accentColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: accentColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T groupValue,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : textColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: textColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context, {
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required Color textColor,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 14)),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: textColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 12,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedbackHelper.selectionClick();
              onChanged(newValue);
            },
            activeThumbColor: accentColor,
            inactiveThumbColor: textColor.withValues(alpha: 0.5),
            inactiveTrackColor: textColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
