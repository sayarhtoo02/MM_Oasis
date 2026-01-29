import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_surah.dart';
import '../models/quran_ayah.dart';

import '../models/mashaf_models.dart';
import '../services/offline_quran_service.dart';
import '../services/mashaf_service.dart';
import '../services/reading_stats_service.dart';

class QuranProvider extends ChangeNotifier {
  final OfflineQuranService _quranService = OfflineQuranService();
  final MashafService _mashafService = MashafService();

  List<QuranSurah> _surahs = [];
  final Map<int, List<QuranAyah>> _ayahsCache = {};
  bool _isLoading = false;
  String _selectedLanguage = 'english';
  List<String> _selectedTranslationKeys = ['ghazi']; // Default to Ghazi Hashim
  final List<String> _availableTranslations = ['basein', 'ghazi', 'hashim'];

  // Mashaf Mode State
  bool _isMashafMode = false;
  MashafInfo? _mashafInfo;
  String? _mashafError;
  final Map<int, List<MashafPageLine>> _mashafPagesCache = {};

  // Persistence State
  Map<String, dynamic>? _lastRead;
  List<Map<String, dynamic>> _bookmarks = [];

  List<QuranSurah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  List<String> get selectedTranslationKeys => _selectedTranslationKeys;
  List<String> get availableTranslations => _availableTranslations;

  bool get isMashafMode => _isMashafMode;
  MashafInfo? get mashafInfo => _mashafInfo;
  String? get mashafError => _mashafError;

  Map<String, dynamic>? get lastRead => _lastRead;
  List<Map<String, dynamic>> get bookmarks => _bookmarks;

  // Compatibility getter for single translation key
  String get selectedTranslationKey => _selectedTranslationKeys.isNotEmpty
      ? _selectedTranslationKeys.first
      : 'ghazi';

  QuranProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Last Read
    final lastReadString = prefs.getString('quran_last_read');
    if (lastReadString != null) {
      _lastRead = json.decode(lastReadString);
    }

    // Load Bookmarks
    final bookmarksString = prefs.getString('quran_bookmarks');
    if (bookmarksString != null) {
      _bookmarks = List<Map<String, dynamic>>.from(
        json.decode(bookmarksString),
      );
    }

    // Load View Mode
    _isMashafMode = prefs.getBool('quran_is_mashaf_mode') ?? false;

    // Load Translation Preference
    final savedTranslations = prefs.getStringList(
      'quran_selected_translations',
    );
    if (savedTranslations != null && savedTranslations.isNotEmpty) {
      _selectedTranslationKeys = savedTranslations;
    } else {
      // Fallback to legacy single key if exists
      final legacyKey = prefs.getString('quran_selected_translation');
      if (legacyKey != null) {
        _selectedTranslationKeys = [legacyKey];
      }
    }

    notifyListeners();
  }

  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
    required int pageNumber,
    required String surahName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _lastRead = {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
      'surahName': surahName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('quran_last_read', json.encode(_lastRead));

    // Record progress in stats database
    await ReadingStatsService.markAyahRead(surahNumber, ayahNumber);

    notifyListeners();
  }

  Future<void> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    int? pageNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final existingIndex = _bookmarks.indexWhere(
      (b) => b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber,
    );

    if (existingIndex != -1) {
      _bookmarks.removeAt(existingIndex);
    } else {
      _bookmarks.add({
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'pageNumber': pageNumber ?? 0,
        'surahName': surahName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    await prefs.setString('quran_bookmarks', json.encode(_bookmarks));
    notifyListeners();
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarks.any(
      (b) => b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber,
    );
  }

  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _surahs = await _quranService.getAllSurahs();
    } catch (e) {
      debugPrint('Error loading surahs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber) async {
    try {
      if (_ayahsCache.containsKey(surahNumber)) {
        return {'ayahs': _ayahsCache[surahNumber]};
      }

      final result = await _quranService.getSurahWithAyahs(surahNumber);
      final ayahs = result['ayahs'] as List<QuranAyah>?;

      if (ayahs != null) {
        _ayahsCache[surahNumber] = ayahs;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  Future<QuranAyah?> getAyah(int surahNumber, int ayahNumber) async {
    return await _quranService.getAyah(surahNumber, ayahNumber);
  }

  // Search
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // Search in the first selected translation by default for now
      final searchKey = _selectedTranslationKeys.isNotEmpty
          ? _selectedTranslationKeys.first
          : 'basein';
      _searchResults = await _quranService.searchAyahs(query, searchKey);
    } catch (e) {
      debugPrint('Error searching: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getSurahInfo(int surahNumber) async {
    return await _quranService.getSurahInfo(surahNumber);
  }

  void setLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      _ayahsCache.clear();
      notifyListeners();
    }
  }

  Future<void> setTranslationKey(String key) async {
    if (_availableTranslations.contains(key)) {
      _selectedTranslationKeys = [key];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('quran_selected_translations', [key]);
      notifyListeners();
    }
  }

  Future<void> toggleTranslationKey(String key) async {
    if (!_availableTranslations.contains(key)) return;

    if (_selectedTranslationKeys.contains(key)) {
      if (_selectedTranslationKeys.length > 1) {
        _selectedTranslationKeys.remove(key);
      }
    } else {
      _selectedTranslationKeys.add(key);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'quran_selected_translations',
      _selectedTranslationKeys,
    );
    notifyListeners();
  }

  // Mashaf Mode Methods
  Future<void> toggleMode() async {
    _isMashafMode = !_isMashafMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quran_is_mashaf_mode', _isMashafMode);
    notifyListeners();
  }

  Future<void> loadMashafInfo() async {
    if (_mashafInfo != null) return;

    try {
      _mashafError = null;
      _mashafInfo = await _mashafService.getMashafInfo();
    } catch (e) {
      _mashafError = e.toString();
      debugPrint('Error loading mashaf info: $e');
    }
    notifyListeners();
  }

  Future<List<MashafPageLine>> getMashafPage(int pageNumber) async {
    if (_mashafPagesCache.containsKey(pageNumber)) {
      return _mashafPagesCache[pageNumber]!;
    }

    final lines = await _mashafService.getPageLines(pageNumber);
    if (lines.isNotEmpty) {
      _mashafPagesCache[pageNumber] = lines;
    }
    return lines;
  }

  Future<int> getSurahStartPage(int surahNumber) async {
    return await _mashafService.getSurahStartPage(surahNumber);
  }

  Future<int> getSurahForPage(int pageNumber) async {
    return await _mashafService.getSurahForPage(pageNumber);
  }

  Future<int> getPageForAyah(int surahNumber, int ayahNumber) async {
    return await _mashafService.getPageForAyah(surahNumber, ayahNumber);
  }

  Future<void> recordPageProgress(int pageNumber) async {
    try {
      final verses = await _mashafService.getVersesOnPage(pageNumber);
      if (verses.isNotEmpty) {
        await ReadingStatsService.markPageRead(verses);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recording page progress: $e');
    }
  }

  Future<void> resetTracking() async {
    await ReadingStatsService.resetAllTracking();
    notifyListeners();
  }

  Future<void> clearCache() async {
    _quranService.clearCache();
    _surahs.clear();
    _ayahsCache.clear();
    _mashafPagesCache.clear();
    notifyListeners();
  }
}
