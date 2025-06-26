import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/widgets/custom_app_bar.dart';
import 'package:munajat_e_maqbool_app/services/dua_repository.dart'; // Import DuaRepository
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart'; // Import DuaDetailScreen

class CustomCollectionDetailScreen extends StatefulWidget {
  static const routeName = '/custom-collection-detail';
  final CustomCollection collection;

  const CustomCollectionDetailScreen({super.key, required this.collection});

  @override
  State<CustomCollectionDetailScreen> createState() => _CustomCollectionDetailScreenState();
}

class _CustomCollectionDetailScreenState extends State<CustomCollectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final duaProvider = Provider.of<DuaProvider>(context);

    // Get the updated collection from the settingsProvider to ensure reactivity
    final currentCollection = settingsProvider.appSettings.duaPreferences.customCollections
        .firstWhere((col) => col.id == widget.collection.id, orElse: () => widget.collection);

    final List<Dua> duasInCollection = duaProvider.allDuas
        .where((dua) => currentCollection.duaIds.contains(dua.id))
        .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: currentCollection.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDuaDialog(context, currentCollection, duaProvider, settingsProvider),
          ),
        ],
      ),
      body: duasInCollection.isEmpty
          ? const Center(
              child: Text('No Duas in this collection yet. Add some!'),
            )
          : ListView.builder(
              itemCount: duasInCollection.length,
              itemBuilder: (context, index) {
                final dua = duasInCollection[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(dua.arabicText), // Display Arabic text or a suitable identifier
                    subtitle: Text(dua.translations.english), // Display English translation
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        settingsProvider.removeDuaFromCustomCollection(currentCollection.id, dua.id);
                      },
                    ),
                    onTap: () async {
                      final duaRepository = DuaRepository();
                      final manzilDuas = await duaRepository.getDuasByManzil(dua.manzilNumber);
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

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Duas to Collection'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: availableDuas.length,
              itemBuilder: (context, index) {
                final dua = availableDuas[index];
                final bool isAlreadyInCollection = currentCollection.duaIds.contains(dua.id);
                final bool isSelectedForAdding = selectedDuasToAdd.contains(dua);

                return CheckboxListTile(
                  title: Text(dua.arabicText),
                  subtitle: Text(dua.translations.english),
                  value: isAlreadyInCollection || isSelectedForAdding,
                  onChanged: isAlreadyInCollection
                      ? null // Disable if already in collection
                      : (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedDuasToAdd.add(dua);
                            } else {
                              selectedDuasToAdd.remove(dua);
                            }
                          });
                          // Rebuild the dialog to reflect changes
                          (dialogContext as Element).markNeedsBuild();
                        },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add Selected'),
              onPressed: () {
                for (final dua in selectedDuasToAdd) {
                  if (!currentCollection.duaIds.contains(dua.id)) {
                    settingsProvider.addDuaToCustomCollection(currentCollection.id, dua.id);
                  }
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
