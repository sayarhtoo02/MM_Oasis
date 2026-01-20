import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/language_settings.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../utils/haptic_feedback_helper.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final languageSettings = settingsProvider.appSettings.languageSettings;

        return GlassScaffold(
          title: 'Language',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Translation Language',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose your preferred language for dua translations',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._buildLanguageOptions(
                      context,
                      languageSettings,
                      settingsProvider,
                      isDark,
                      textColor,
                      accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildLanguageOptions(
    BuildContext context,
    LanguageSettings settings,
    SettingsProvider provider,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'my', 'name': 'Burmese', 'flag': '🇲🇲'},
      {'code': 'ur', 'name': 'Urdu', 'flag': '🇵🇰'},
    ];

    return languages
        .map(
          (lang) => _buildLanguageOption(
            context,
            code: lang['code']!,
            name: lang['name']!,
            flag: lang['flag']!,
            isSelected: settings.selectedLanguage == lang['code'],
            textColor: textColor,
            accentColor: accentColor,
            onTap: () {
              HapticFeedbackHelper.selectionClick();
              provider.setSelectedLanguage(lang['code']!);
            },
          ),
        )
        .toList();
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String code,
    required String name,
    required String flag,
    required bool isSelected,
    required Color textColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : textColor.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? accentColor : textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
