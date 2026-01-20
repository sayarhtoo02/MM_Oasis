import 'package:shared_preferences/shared_preferences.dart';

class ReadingStatsService {
  static const String _lastReadDateKey = 'last_read_date';
  static const String _streakCountKey = 'streak_count';
  static const String _totalDuasReadKey = 'total_duas_read';

  Future<void> updateReadingStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastReadStr = prefs.getString(_lastReadDateKey);
    
    if (lastReadStr == null) {
      await prefs.setString(_lastReadDateKey, todayStr);
      await prefs.setInt(_streakCountKey, 1);
    } else {
      final lastRead = _parseDate(lastReadStr);
      final diff = today.difference(lastRead).inDays;
      
      if (diff == 0) {
        return;
      } else if (diff == 1) {
        final currentStreak = prefs.getInt(_streakCountKey) ?? 0;
        await prefs.setInt(_streakCountKey, currentStreak + 1);
        await prefs.setString(_lastReadDateKey, todayStr);
      } else {
        await prefs.setInt(_streakCountKey, 1);
        await prefs.setString(_lastReadDateKey, todayStr);
      }
    }
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_streakCountKey) ?? 0;
    final lastReadStr = prefs.getString(_lastReadDateKey);
    
    if (lastReadStr != null) {
      final lastRead = _parseDate(lastReadStr);
      final today = DateTime.now();
      final diff = today.difference(lastRead).inDays;
      
      if (diff > 1) {
        await prefs.setInt(_streakCountKey, 0);
        return 0;
      }
    }
    
    return streak;
  }

  Future<void> incrementDuasRead() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_totalDuasReadKey) ?? 0;
    await prefs.setInt(_totalDuasReadKey, count + 1);
  }

  Future<int> getTotalDuasRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalDuasReadKey) ?? 0;
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
