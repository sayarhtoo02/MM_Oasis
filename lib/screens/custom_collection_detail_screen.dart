import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/services/dua_repository.dart'; // Import DuaRepository
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart'; // Import DuaDetailScreen

class CustomCollectionDetailScreen extends StatefulWidget {
  static const routeName = '/custom-collection-detail';
  final CustomCollection collection;

  const CustomCollectionDetailScreen({super.key, required this.collection});

  @override
  State<CustomCollectionDetailScreen> createState() =>
      _CustomCollectionDetailScreenState();
}

class _CustomCollectionDetailScreenState
    extends State<CustomCollectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final duaProvider = Provider.of<DuaProvider>(context);

    // Get the updated collection from the settingsProvider to ensure reactivity
    final currentCollection = settingsProvider
        .appSettings
        .duaPreferences
        .customCollections
        .firstWhere(
          (col) => col.id == widget.collection.id,
          orElse: () => widget.collection,
        );

    final List<Dua> duasInCollection = duaProvider.allDuas
        .where((dua) => currentCollection.duaIds.contains(dua.id))
        .toList();

    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    return GlassScaffold(
      title: currentCollection.name,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.add_rounded, color: accentColor),
            onPressed: () => _showAddDuaDialog(
              context,
              currentCollection,
              duaProvider,
              settingsProvider,
            ),
          ),
        ),
      ],
      body: duasInCollection.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add_rounded,
                    size: 64,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Duas in this collection yet.',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add some!',
                    style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: duasInCollection.length,
              itemBuilder: (context, index) {
                final dua = duasInCollection[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    isDark: isDark,
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    onTap: () async {
                      final duaRepository = DuaRepository();
                      final manzilDuas = await duaRepository.getDuasByManzil(
                        dua.manzilNumber,
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DuaDetailScreen(
                            initialDua: dua,
                            manzilDuas: manzilDuas,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'Manzil ${dua.manzilNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.red.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                onPressed: () {
                                  settingsProvider
                                      .removeDuaFromCustomCollection(
                                        currentCollection.id,
                                        dua.id,
                                      );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            dua.arabicText,
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Indopak',
                              fontSize: 24,
                              letterSpacing: 0,
                              height: 1.5,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dua.translations.english,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDuaDialog(
    BuildContext context,
    CustomCollection currentCollection,
    DuaProvider duaProvider,
    SettingsProvider settingsProvider,
  ) {
    final List<Dua> availableDuas = duaProvider.allDuas;
    final List<Dua> selectedDuasToAdd = [];
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            isDark: isDark,
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Duas to Collection',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableDuas.length,
                          itemBuilder: (context, index) {
                            final dua = availableDuas[index];
                            final bool isAlreadyInCollection = currentCollection
                                .duaIds
                                .contains(dua.id);
                            final bool isSelected = selectedDuasToAdd.contains(
                              dua,
                            );

                            return Theme(
                              data: Theme.of(context).copyWith(
                                checkboxTheme: CheckboxThemeData(
                                  fillColor: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return accentColor;
                                    }
                                    return Colors.transparent;
                                  }),
                                  side: BorderSide(
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                  checkColor: WidgetStateProperty.all(
                                    isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  dua.arabicText,
                                  style: TextStyle(
                                    fontFamily: 'Indopak',
                                    color: textColor,
                                    letterSpacing: 0,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  dua.translations.english,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                value: isAlreadyInCollection || isSelected,
                                activeColor: accentColor,
                                checkColor: isDark
                                    ? Colors.black
                                    : Colors.white,
                                side: BorderSide(
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                                onChanged: isAlreadyInCollection
                                    ? null
                                    : (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedDuasToAdd.add(dua);
                                          } else {
                                            selectedDuasToAdd.remove(dua);
                                          }
                                        });
                                      },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              for (final dua in selectedDuasToAdd) {
                                if (!currentCollection.duaIds.contains(
                                  dua.id,
                                )) {
                                  settingsProvider.addDuaToCustomCollection(
                                    currentCollection.id,
                                    dua.id,
                                  );
                                }
                              }
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Add Selected'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
