import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DailyHadithService {
  static const List<Map<String, String>> _hadiths = [
    {
      'text': 'The best of you are those who are best to their families.',
      'reference': 'Tirmidhi 3895'
    },
    {
      'text': 'A believer does not taunt, curse, abuse or talk indecently.',
      'reference': 'Tirmidhi 1977'
    },
    {
      'text': 'The strong person is not the one who can wrestle someone else down. The strong person is the one who can control himself when he is angry.',
      'reference': 'Bukhari 6114'
    },
    {
      'text': 'Whoever believes in Allah and the Last Day should speak good or remain silent.',
      'reference': 'Bukhari 6018'
    },
    {
      'text': 'The most beloved deeds to Allah are those that are most consistent, even if they are small.',
      'reference': 'Bukhari 6464'
    },
    {
      'text': 'Make things easy and do not make them difficult, cheer people up and do not repel them.',
      'reference': 'Bukhari 69'
    },
    {
      'text': 'None of you truly believes until he loves for his brother what he loves for himself.',
      'reference': 'Bukhari 13'
    },
  ];

  static Future<Map<String, String>> getDailyHadith() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final savedDate = prefs.getString('daily_hadith_date');
    
    if (savedDate != todayStr) {
      final index = Random(today.day + today.month * 100 + today.year * 10000).nextInt(_hadiths.length);
      await prefs.setString('daily_hadith_date', todayStr);
      await prefs.setInt('daily_hadith_index', index);
      return _hadiths[index];
    }
    
    final savedIndex = prefs.getInt('daily_hadith_index') ?? 0;
    return _hadiths[savedIndex];
  }
}
