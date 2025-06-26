import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dua_model.dart';
import '../../providers/settings_provider.dart';
import '../../models/custom_collection.dart'; // Import CustomCollection

class DuaDetailAppBarActions extends StatelessWidget {
  final Dua currentDua;
  final String selectedLanguage;
  final Function(Dua, String) onCopyDuaText;
  final Function(Dua, String) onShareDuaText;

  const DuaDetailAppBarActions({
    super.key,
    required this.currentDua,
    required this.selectedLanguage,
    required this.onCopyDuaText,
    required this.onShareDuaText,
  });

  void _showAddToCollectionDialog(BuildContext context, Dua dua, SettingsProvider settingsProvider) {
    final List<CustomCollection> customCollections = settingsProvider.appSettings.duaPreferences.customCollections;
    TextEditingController newCollectionNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customCollections.isNotEmpty) ...[
                  const Text('Select an existing collection:'),
                  ...customCollections.map((collection) {
                    final bool isInCollection = collection.duaIds.contains(dua.id);
                    return CheckboxListTile(
                      title: Text(collection.name),
                      value: isInCollection,
                      onChanged: (bool? value) {
                        if (value != null) {
                          if (value) {
                            // Add dua to collection
                            if (!isInCollection) {
                              collection.duaIds.add(dua.id);
                              settingsProvider.updateCustomCollection(collection);
                            }
                          } else {
                            // Remove dua from collection
                            if (isInCollection) {
                              collection.duaIds.remove(dua.id);
                              settingsProvider.updateCustomCollection(collection);
                            }
                          }
                          Navigator.of(context).pop(); // Close dialog after selection
                        }
                      },
                    );
                  }).toList(),
                  const Divider(),
                ],
                const Text('Or create a new collection:'),
                TextField(
                  controller: newCollectionNameController,
                  decoration: const InputDecoration(hintText: 'New Collection Name'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create & Add'),
              onPressed: () {
                final String newName = newCollectionNameController.text.trim();
                if (newName.isNotEmpty) {
                  final newCollection = CustomCollection(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: newName,
                    duaIds: [dua.id],
                  );
                  settingsProvider.addCustomCollection(newCollection);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy Dua Text',
          onPressed: () => onCopyDuaText(currentDua, selectedLanguage),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share Dua',
          onPressed: () => onShareDuaText(currentDua, selectedLanguage),
        ),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final isFavorite = settingsProvider.isDuaFavorite(currentDua);
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                settingsProvider.toggleFavoriteDua(currentDua);
              },
            );
          },
        ),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: 'Add to Collection',
              onPressed: () => _showAddToCollectionDialog(context, currentDua, settingsProvider),
            );
          },
        ),
      ],
    );
  }
}
