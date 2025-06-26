import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import 'package:munajat_e_maqbool_app/services/dua_repository.dart';
import 'package:munajat_e_maqbool_app/utils/arabic_utils.dart'; // Import the new utility
import 'dart:async'; // For Timer

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Dua> _searchResults = [];
  Timer? _debounce;
  int? _selectedManzilFilter; // New state variable for Manzil filter

  final List<String> _manzilOptions = [
    'All Manzils',
    "Manzil 1", "Manzil 2", "Manzil 3", "Manzil 4", "Manzil 5", "Manzil 6", "Manzil 7",
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final String selectedLanguage = settingsProvider.appSettings.languageSettings.selectedLanguage;

    debugPrint('Performing search for query: "$query"');
    debugPrint('DuaProvider.allDuas size: ${duaProvider.allDuas.length}');

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      debugPrint('Query is empty, search results cleared.');
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final cleanedQuery = removeTashkeel(lowerCaseQuery); // Clean the query
    debugPrint('Lowercase query: "$lowerCaseQuery", Cleaned query: "$cleanedQuery"');

    setState(() {
      _searchResults = duaProvider.allDuas.where((dua) {
        final arabicText = removeTashkeel(dua.arabicText.toLowerCase()); // Clean Arabic text
        final englishTranslation = dua.translations.english.toLowerCase();
        final burmeseTranslation = dua.translations.burmese.toLowerCase();
        final urduTranslation = dua.translations.urdu.toLowerCase();

        final arabicMatch = arabicText.contains(cleanedQuery); // Use cleaned query for Arabic search
        final englishMatch = englishTranslation.contains(lowerCaseQuery);
        final burmeseMatch = burmeseTranslation.contains(lowerCaseQuery);
        final urduMatch = urduTranslation.contains(lowerCaseQuery);

        final manzilMatch = _selectedManzilFilter == null || dua.manzilNumber == _selectedManzilFilter;

        debugPrint('Dua ID: ${dua.id}, Arabic: "$arabicText", English: "$englishTranslation"');
        debugPrint('Matches: Arabic=$arabicMatch, English=$englishMatch, Burmese=$burmeseMatch, Urdu=$urduMatch, Manzil=$manzilMatch');

        return (arabicMatch || englishMatch || burmeseMatch || urduMatch) && manzilMatch;
      }).toList();
    });
    debugPrint('Found ${_searchResults.length} results for query: "$query" with Manzil filter: ${_selectedManzilFilter ?? 'All'}');
  }

  String _getTranslationText(Translations translations, String languageCode) {
    switch (languageCode) {
      case 'ur':
        return translations.urdu;
      case 'en':
        return translations.english;
      case 'my':
        return translations.burmese;
      default:
        return translations.english; // Fallback to English
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final String selectedLanguage = settingsProvider.appSettings.languageSettings.selectedLanguage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Duas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _selectedManzilFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Manzil',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _manzilOptions.map((String manzil) {
                final int? value = manzil == 'All Manzils' ? null : int.parse(manzil.split(' ')[1]);
                return DropdownMenuItem<int?>(
                  value: value,
                  child: Text(manzil),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedManzilFilter = newValue;
                });
                _performSearch(_searchController.text);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _searchResults.isEmpty && _searchController.text.isEmpty && _selectedManzilFilter == null
                  ? Center(
                      child: Text(
                        'Start typing to search for Duas or select a Manzil to filter.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _searchResults.isEmpty && (_searchController.text.isNotEmpty || _selectedManzilFilter != null)
                      ? Center(
                          child: Text(
                            'No Duas found for "${_searchController.text}" in Manzil ${_selectedManzilFilter ?? 'All'}.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final dua = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: InkWell(
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
                                borderRadius: BorderRadius.circular(12.0),
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
                                          fontSize: 24 * settingsProvider.appSettings.displaySettings.arabicFontSizeMultiplier,
                                          height: 1.5,
                                          letterSpacing: 0,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTranslationText(dua.translations, selectedLanguage),
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
            ),
          ],
        ),
      ),
    );
  }
}
