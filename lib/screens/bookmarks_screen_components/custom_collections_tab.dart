import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart';
import '../../widgets/glass/glass_card.dart';
import '../../config/glass_theme.dart';

class CustomCollectionsTab extends StatelessWidget {
  const CustomCollectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final customCollections =
            settingsProvider.appSettings.duaPreferences.customCollections;
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (customCollections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 64,
                  color: textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No custom collections yet.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  isDark: isDark,
                  borderRadius: 12,
                  padding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(CustomCollectionsScreen.routeName);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Create New Collection',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customCollections.length,
          itemBuilder: (context, index) {
            final collection = customCollections[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                isDark: isDark,
                borderRadius: 16,
                padding: EdgeInsets.zero,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    CustomCollectionDetailScreen.routeName,
                    arguments: collection,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              collection.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: 16,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.duaIds.length} Duas',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
