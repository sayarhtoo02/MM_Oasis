import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/widgets/custom_app_bar.dart';
import 'package:munajat_e_maqbool_app/widgets/custom_text_field.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart';

class CustomCollectionsScreen extends StatefulWidget {
  static const routeName = '/custom-collections';

  const CustomCollectionsScreen({super.key});

  @override
  State<CustomCollectionsScreen> createState() => _CustomCollectionsScreenState();
}

class _CustomCollectionsScreenState extends State<CustomCollectionsScreen> {
  final TextEditingController _collectionNameController = TextEditingController();

  void _showAddCollectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Collection'),
          content: SingleChildScrollView(
            child: CustomTextField(
              controller: _collectionNameController,
              labelText: 'Collection Name',
              hintText: 'Enter collection name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _collectionNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_collectionNameController.text.isNotEmpty) {
                  final newCollection = CustomCollection(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _collectionNameController.text,
                    duaIds: [],
                  );
                  Provider.of<SettingsProvider>(context, listen: false)
                      .addCustomCollection(newCollection);
                  _collectionNameController.clear();
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
  void dispose() {
    _collectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Custom Collections',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCollectionDialog,
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final customCollections = settingsProvider.appSettings.duaPreferences.customCollections;

          if (customCollections.isEmpty) {
            return const Center(
              child: Text('No custom collections yet. Add one to get started!'),
            );
          }

          return ListView.builder(
            itemCount: customCollections.length,
            itemBuilder: (context, index) {
              final collection = customCollections[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text(collection.name),
                  subtitle: Text('${collection.duaIds.length} Duas'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditCollectionDialog(collection, settingsProvider);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          settingsProvider.removeCustomCollection(collection.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      CustomCollectionDetailScreen.routeName,
                      arguments: collection,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditCollectionDialog(CustomCollection collection, SettingsProvider settingsProvider) {
    _collectionNameController.text = collection.name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Collection Name'),
          content: SingleChildScrollView(
            child: CustomTextField(
              controller: _collectionNameController,
              labelText: 'Collection Name',
              hintText: 'Enter new collection name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _collectionNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (_collectionNameController.text.isNotEmpty) {
                  final updatedCollection = collection.copyWith(name: _collectionNameController.text);
                  settingsProvider.updateCustomCollection(updatedCollection);
                  _collectionNameController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
