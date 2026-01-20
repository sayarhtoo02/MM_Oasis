import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DuaPreferencesScreen extends StatelessWidget {
  const DuaPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final duaPreferences = settingsProvider.appSettings.duaPreferences;

        return GlassScaffold(
          title: 'Dua Preferences',
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Last Read Dua',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (duaPreferences.lastReadDua != null)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/dua_detail',
                            arguments: {
                              'selectedDua': duaPreferences.lastReadDua,
                              'manzilDuas': [],
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${duaPreferences.lastReadDua!.arabicText.split(' ').take(5).join(' ')}...',
                                style: GoogleFonts.amiriQuran(
                                  fontSize:
                                      18 *
                                      settingsProvider
                                          .appSettings
                                          .displaySettings
                                          .arabicFontSizeMultiplier,
                                  color: textColor,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${duaPreferences.lastReadDua!.translations.english.split(' ').take(10).join(' ')}...',
                                style: TextStyle(
                                  fontSize:
                                      14 *
                                      settingsProvider
                                          .appSettings
                                          .displaySettings
                                          .translationFontSizeMultiplier,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'No last read Dua.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Favorite Duas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (duaPreferences.favoriteDuas.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: duaPreferences.favoriteDuas.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: textColor.withValues(alpha: 0.1)),
                        itemBuilder: (context, index) {
                          final dua = duaPreferences.favoriteDuas[index];
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/dua_detail',
                                arguments: {
                                  'selectedDua': dua,
                                  'manzilDuas': [],
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${dua.arabicText.split(' ').take(5).join(' ')}...',
                                          style: GoogleFonts.amiriQuran(
                                            fontSize:
                                                16 *
                                                settingsProvider
                                                    .appSettings
                                                    .displaySettings
                                                    .arabicFontSizeMultiplier,
                                            color: textColor,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dua.translations.english.split(' ').take(8).join(' ')}...',
                                          style: TextStyle(
                                            fontSize:
                                                12 *
                                                settingsProvider
                                                    .appSettings
                                                    .displaySettings
                                                    .translationFontSizeMultiplier,
                                            color: textColor.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () {
                                      settingsProvider.toggleFavoriteDua(dua);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        'No favorite Duas yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.6),
                        ),
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
}
