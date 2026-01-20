import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_analytics.dart';

class AnalyticsService {
  static const String _sessionsKey = 'reading_sessions';
  static const String _dailyStatsKey = 'daily_stats';
  static const String _achievementsKey = 'achievements';

  Future<void> recordReadingSession(ReadingSession session) async {
    debugPrint(
      'Analytics Service: Recording session - Duration: ${session.readingDuration.inSeconds}s',
    );
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getReadingSessions();
    sessions.add(session);

    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    debugPrint('Analytics Service: Saved ${sessions.length} total sessions');

    await _updateDailyStats(session);
    await _checkAchievements();
  }

  Future<List<ReadingSession>> getReadingSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null) return [];

      final List<dynamic> sessionsList = jsonDecode(sessionsJson);
      return sessionsList.map((json) => ReadingSession.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading reading sessions: $e');
      return [];
    }
  }

  Future<DailyStats> getDailyStats(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_dailyStatsKey);
      if (statsJson == null) return _createEmptyDailyStats(date);

      final Map<String, dynamic> statsMap = jsonDecode(statsJson);
      final dateKey = _formatDate(date);

      if (statsMap.containsKey(dateKey)) {
        return DailyStats.fromJson(statsMap[dateKey]);
      }

      return _createEmptyDailyStats(date);
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
      return _createEmptyDailyStats(date);
    }
  }

  Future<List<DailyStats>> getWeeklyStats() async {
    final List<DailyStats> weekStats = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final stats = await getDailyStats(date);
      weekStats.add(stats);
    }

    return weekStats;
  }

  Future<int> getCurrentStreak() async {
    final sessions = await getReadingSessions();
    if (sessions.isEmpty) return 0;

    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final checkDate = currentDate.subtract(Duration(days: i));
      final hasSessionOnDate = sessions.any(
        (session) => _isSameDay(session.startTime, checkDate),
      );

      if (hasSessionOnDate) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  Future<Duration> getTotalReadingTime() async {
    final sessions = await getReadingSessions();
    return sessions.fold<Duration>(
      Duration.zero,
      (Duration total, ReadingSession session) =>
          total + session.readingDuration,
    );
  }

  Future<Map<int, double>> getManzilProgress() async {
    final sessions = await getReadingSessions();
    final Map<int, Set<String>> manzilDuas = {};

    for (final session in sessions) {
      manzilDuas.putIfAbsent(session.manzilNumber, () => <String>{});
      manzilDuas[session.manzilNumber]!.add(session.duaId);
    }

    // Assuming each manzil has approximately 10 duas (adjust as needed)
    const int duasPerManzil = 10;
    final Map<int, double> progress = {};

    for (int i = 1; i <= 7; i++) {
      final completedDuas = manzilDuas[i]?.length ?? 0;
      progress[i] = (completedDuas / duasPerManzil).clamp(0.0, 1.0);
    }

    return progress;
  }

  Future<void> _updateDailyStats(ReadingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_dailyStatsKey) ?? '{}';
    final Map<String, dynamic> statsMap = jsonDecode(statsJson);

    final dateKey = _formatDate(session.startTime);
    final existingStats = statsMap.containsKey(dateKey)
        ? DailyStats.fromJson(statsMap[dateKey])
        : _createEmptyDailyStats(session.startTime);

    final updatedStats = DailyStats(
      date: existingStats.date,
      totalSessions: existingStats.totalSessions + 1,
      totalReadingTime:
          existingStats.totalReadingTime + session.readingDuration,
      manzilsRead: {...existingStats.manzilsRead, session.manzilNumber},
      duasCompleted: existingStats.duasCompleted + 1,
    );

    statsMap[dateKey] = updatedStats.toJson();
    await prefs.setString(_dailyStatsKey, jsonEncode(statsMap));
  }

  Future<void> _checkAchievements() async {
    final streak = await getCurrentStreak();
    final totalTime = await getTotalReadingTime();
    final sessions = await getReadingSessions();

    final achievements = <Achievement>[];

    if (streak >= 7) {
      achievements.add(
        Achievement(
          id: 'week_streak',
          title: '7-Day Streak',
          description: 'Read duas for 7 consecutive days',
          iconName: 'local_fire_department',
          unlockedAt: DateTime.now(),
          isUnlocked: true,
        ),
      );
    }

    if (totalTime.inHours >= 10) {
      achievements.add(
        Achievement(
          id: 'ten_hours',
          title: 'Dedicated Reader',
          description: 'Spent 10 hours reading duas',
          iconName: 'schedule',
          unlockedAt: DateTime.now(),
          isUnlocked: true,
        ),
      );
    }

    if (sessions.length >= 100) {
      achievements.add(
        Achievement(
          id: 'hundred_sessions',
          title: 'Century Reader',
          description: 'Completed 100 reading sessions',
          iconName: 'military_tech',
          unlockedAt: DateTime.now(),
          isUnlocked: true,
        ),
      );
    }

    await _saveAchievements(achievements);
  }

  Future<void> _saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = achievements.map((a) => a.toJson()).toList();
    await prefs.setString(_achievementsKey, jsonEncode(achievementsJson));
  }

  DailyStats _createEmptyDailyStats(DateTime date) {
    return DailyStats(
      date: date,
      totalSessions: 0,
      totalReadingTime: Duration.zero,
      manzilsRead: <int>{},
      duasCompleted: 0,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_dailyStatsKey);
    await prefs.remove(_achievementsKey);
  }
}
