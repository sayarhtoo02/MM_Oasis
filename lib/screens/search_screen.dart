import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import 'package:munajat_e_maqbool_app/services/dua_repository.dart';
import 'package:munajat_e_maqbool_app/utils/arabic_utils.dart';
import 'dart:async';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Dua> _searchResults = [];
  Timer? _debounce;
  int? _selectedManzilFilter;

  final List<String> _manzilOptions = [
    'All Manzils',
    "Manzil 1",
    "Manzil 2",
    "Manzil 3",
    "Manzil 4",
    "Manzil 5",
    "Manzil 6",
    "Manzil 7",
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

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final cleanedQuery = removeTashkeel(lowerCaseQuery);

    setState(() {
      _searchResults = duaProvider.allDuas.where((dua) {
        final arabicText = removeTashkeel(dua.arabicText.toLowerCase());
        final englishTranslation = dua.translations.english.toLowerCase();
        final burmeseTranslation = dua.translations.burmese.toLowerCase();
        final urduTranslation = dua.translations.urdu.toLowerCase();

        final arabicMatch = arabicText.contains(cleanedQuery);
        final englishMatch = englishTranslation.contains(lowerCaseQuery);
        final burmeseMatch = burmeseTranslation.contains(lowerCaseQuery);
        final urduMatch = urduTranslation.contains(lowerCaseQuery);

        final manzilMatch =
            _selectedManzilFilter == null ||
            dua.manzilNumber == _selectedManzilFilter;

        return (arabicMatch || englishMatch || burmeseMatch || urduMatch) &&
            manzilMatch;
      }).toList();
    });
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
        return translations.english;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final selectedLanguage =
            settingsProvider.appSettings.languageSettings.selectedLanguage;

        return GlassScaffold(
          title: 'Search Duas',
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Search...',
                    labelStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: textColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Manzil Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textColor.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedManzilFilter,
                      dropdownColor: GlassTheme.background(isDark),
                      style: TextStyle(color: textColor),
                      isExpanded: true,
                      hint: Text(
                        'Filter by Manzil',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      items: _manzilOptions.map((String manzil) {
                        final int? value = manzil == 'All Manzils'
                            ? null
                            : int.parse(manzil.split(' ')[1]);
                        return DropdownMenuItem<int?>(
                          value: value,
                          child: Text(
                            manzil,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedManzilFilter = newValue;
                        });
                        _performSearch(_searchController.text);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Results
                Expanded(
                  child:
                      _searchResults.isEmpty &&
                          _searchController.text.isEmpty &&
                          _selectedManzilFilter == null
                      ? Center(
                          child: Text(
                            'Start typing to search for Duas or select a Manzil to filter.',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _searchResults.isEmpty &&
                            (_searchController.text.isNotEmpty ||
                                _selectedManzilFilter != null)
                      ? Center(
                          child: Text(
                            'No Duas found for "${_searchController.text}" in Manzil ${_selectedManzilFilter ?? 'All'}.',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final dua = _searchResults[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                isDark: isDark,
                                borderRadius: 16,
                                padding: EdgeInsets.zero,
                                onTap: () async {
                                  final duaRepository = DuaRepository();
                                  final manzilDuas = await duaRepository
                                      .getDuasByManzil(dua.manzilNumber);
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Manzil ${dua.manzilNumber} - Day ${dua.day}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        dua.arabicText,
                                        textAlign: TextAlign.justify,
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: 'Indopak',
                                          fontSize:
                                              20 *
                                              settingsProvider
                                                  .appSettings
                                                  .displaySettings
                                                  .arabicFontSizeMultiplier,
                                          height: 1.5,
                                          letterSpacing: 0,
                                          color: textColor,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTranslationText(
                                          dua.translations,
                                          selectedLanguage,
                                        ),
                                        style: TextStyle(
                                          fontSize:
                                              14 *
                                              settingsProvider
                                                  .appSettings
                                                  .displaySettings
                                                  .translationFontSizeMultiplier,
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
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
      },
    );
  }
}
