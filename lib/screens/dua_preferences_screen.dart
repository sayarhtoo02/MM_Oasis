import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../models/dua_preferences.dart'; // Import DuaPreferences
import '../screens/settings_screen_components/settings_card.dart';

class DuaPreferencesScreen extends StatelessWidget {
  const DuaPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dua Preferences',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Selector<SettingsProvider, DuaPreferences>(
        selector: (context, provider) => provider.appSettings.duaPreferences,
        builder: (context, duaPreferences, child) {
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.surface, colorScheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                SettingsCard(
                  title: 'Last Read Dua',
                  icon: Icons.history,
                  children: [
                    if (duaPreferences.lastReadDua != null)
                      ListTile(
                        title: Text(
                          '${duaPreferences.lastReadDua!.arabicText.split(' ').take(5).join(' ')}...',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * settingsProvider.appSettings.displaySettings.arabicFontSizeMultiplier,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        subtitle: Text(
                          '${duaPreferences.lastReadDua!.translations.english.split(' ').take(10).join(' ')}...',
                          style: GoogleFonts.poppins(
                            fontSize: 14 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          // Navigate to Dua Detail Screen
                          Navigator.of(context).pushNamed(
                            '/dua_detail',
                            arguments: {
                              'selectedDua': duaPreferences.lastReadDua,
                              'manzilDuas': [], // You might need to pass actual manzilDuas here
                            },
                          );
                        },
                      )
                    else
                      Text(
                        'No last read Dua.',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                          color: colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsCard(
                  title: 'Favorite Duas',
                  icon: Icons.favorite,
                  children: [
                    if (duaPreferences.favoriteDuas.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: duaPreferences.favoriteDuas.length,
                        itemBuilder: (context, index) {
                          final dua = duaPreferences.favoriteDuas[index];
                          return ListTile(
                            title: Text(
                              '${dua.arabicText.split(' ').take(5).join(' ')}...',
                              style: GoogleFonts.poppins(
                                fontSize: 16 * settingsProvider.appSettings.displaySettings.arabicFontSizeMultiplier,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              '${dua.translations.english.split(' ').take(10).join(' ')}...',
                              style: GoogleFonts.poppins(
                                fontSize: 14 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.favorite, color: colorScheme.error),
                              onPressed: () {
                                settingsProvider.toggleFavoriteDua(dua);
                              },
                            ),
                            onTap: () {
                              // Navigate to Dua Detail Screen
                              Navigator.of(context).pushNamed(
                                '/dua_detail',
                                arguments: {
                                  'selectedDua': dua,
                                  'manzilDuas': [], // You might need to pass actual manzilDuas here
                                },
                              );
                            },
                          );
                        },
                      )
                    else
                      Text(
                        'No favorite Duas yet.',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                          color: colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
