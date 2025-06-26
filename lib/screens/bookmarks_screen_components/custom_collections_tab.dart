import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart'; // To navigate to the full management screen

class CustomCollectionsTab extends StatelessWidget {
  const CustomCollectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final customCollections = settingsProvider.appSettings.duaPreferences.customCollections;

        if (customCollections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No custom collections yet.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(CustomCollectionsScreen.routeName);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Collection'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: customCollections.length,
          itemBuilder: (context, index) {
            final collection = customCollections[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    CustomCollectionDetailScreen.routeName,
                    arguments: collection,
                  );
                },
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${collection.duaIds.length} Duas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
