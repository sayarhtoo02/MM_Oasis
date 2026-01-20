import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../config/glass_theme.dart';

class CustomCollectionsScreen extends StatefulWidget {
  static const routeName = '/custom-collections';

  const CustomCollectionsScreen({super.key});

  @override
  State<CustomCollectionsScreen> createState() =>
      _CustomCollectionsScreenState();
}

class _CustomCollectionsScreenState extends State<CustomCollectionsScreen> {
  final TextEditingController _collectionNameController =
      TextEditingController();

  void _showAddCollectionDialog() {
    _collectionNameController.clear();
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Collection',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _collectionNameController,
                  style: TextStyle(color: textColor),
                  cursorColor: accentColor,
                  decoration: InputDecoration(
                    labelText: 'Collection Name',
                    labelStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.white10,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: textColor),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_collectionNameController.text.isNotEmpty) {
                          final newCollection = CustomCollection(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: _collectionNameController.text,
                            duaIds: [],
                          );
                          settingsProvider.addCustomCollection(newCollection);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _collectionNameController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final customCollections =
            settingsProvider.appSettings.duaPreferences.customCollections;

        return GlassScaffold(
          title: 'Custom Collections',
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: accentColor),
                onPressed: _showAddCollectionDialog,
              ),
            ),
          ],
          body: customCollections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.collections_bookmark_rounded,
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
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create one!',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.folder_rounded,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      collection.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '${collection.duaIds.length} Duas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      color: textColor.withValues(alpha: 0.6),
                                    ),
                                    onPressed: () {
                                      _showEditCollectionDialog(
                                        collection,
                                        settingsProvider,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      color: Colors.red.withValues(alpha: 0.7),
                                    ),
                                    onPressed: () {
                                      // Suggest adding a confirmation dialog here
                                      settingsProvider.removeCustomCollection(
                                        collection.id,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showEditCollectionDialog(
    CustomCollection collection,
    SettingsProvider settingsProvider,
  ) {
    _collectionNameController.text = collection.name;
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            isDark: isDark,
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Collection Name',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _collectionNameController,
                    style: TextStyle(color: textColor),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      labelText: 'Collection Name',
                      labelStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: textColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.white10,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _collectionNameController.clear();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: textColor),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_collectionNameController.text.isNotEmpty) {
                            final updatedCollection = collection.copyWith(
                              name: _collectionNameController.text,
                            );
                            settingsProvider.updateCustomCollection(
                              updatedCollection,
                            );
                            _collectionNameController.clear();
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save'),
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
  }
}
