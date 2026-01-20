import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HadithHistoryService {
  static const String _recentlyViewedKey = 'recently_viewed_hadiths';
  static const String _searchHistoryKey = 'hadith_search_history';
  static const int _maxHistory = 20;

  Future<void> addRecentlyViewed(String bookKey, int hadithNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getRecentlyViewed();
    
    final item = {'book': bookKey, 'hadith': hadithNumber, 'time': DateTime.now().toIso8601String()};
    history.removeWhere((h) => h['book'] == bookKey && h['hadith'] == hadithNumber);
    history.insert(0, item);
    
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    
    await prefs.setString(_recentlyViewedKey, json.encode(history));
  }

  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recentlyViewedKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  Future<void> addSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    history.remove(query);
    history.insert(0, query);
    
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
}
