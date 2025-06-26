import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/dua_detail_screen.dart';
import '../services/dua_repository.dart';
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen_components/custom_collections_tab.dart'; // Import the new tab

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final favoriteDuas = settingsProvider.appSettings.duaPreferences.favoriteDuas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks & Collections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bookmarks'),
            Tab(text: 'Custom Collections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bookmarks Tab Content
          favoriteDuas.isEmpty
              ? Center(
                  child: Text(
                    'No bookmarked Duas yet. Add some from the Dua Detail screen!',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: favoriteDuas.length,
                  itemBuilder: (context, index) {
                    final dua = favoriteDuas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: InkWell(
                        onTap: () async {
                          // Navigate to DuaDetailScreen for the selected favorite Dua
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
                        borderRadius: BorderRadius.circular(16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manzil ${dua.manzilNumber} - Day ${dua.day}',
                                style: TextStyle(
                                  fontSize: 16 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dua.arabicText,
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Arabic',
                                  fontSize: 28 * settingsProvider.appSettings.displaySettings.arabicFontSizeMultiplier, // Smaller for list view
                                  height: 1.5,
                                  letterSpacing: 0.2,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                settingsProvider.appSettings.languageSettings.selectedLanguage == 'en'
                                    ? dua.translations.english
                                    : settingsProvider.appSettings.languageSettings.selectedLanguage == 'my'
                                        ? dua.translations.burmese
                                        : dua.translations.urdu,
                                style: TextStyle(
                                  fontSize: 14 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          // Custom Collections Tab Content
          const CustomCollectionsTab(),
        ],
      ),
    );
  }
}
