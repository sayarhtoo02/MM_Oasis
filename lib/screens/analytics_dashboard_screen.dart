import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dua_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/achievement_badge.dart';
import '../models/reading_analytics.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  List<DailyStats> _weeklyStats = [];
  int _currentStreak = 0;
  Duration _totalReadingTime = Duration.zero;
  Map<int, double> _manzilProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    final analyticsService = duaProvider.analyticsService;

    try {
      await analyticsService.getReadingSessions();
      final weeklyStats = await analyticsService.getWeeklyStats();
      final currentStreak = await analyticsService.getCurrentStreak();
      final totalTime = await analyticsService.getTotalReadingTime();
      final manzilProgress = await analyticsService.getManzilProgress();

      setState(() {
        _weeklyStats = weeklyStats;
        _currentStreak = currentStreak;
        _totalReadingTime = totalTime;
        _manzilProgress = manzilProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTestData() async {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    final analyticsService = duaProvider.analyticsService;

    final now = DateTime.now();
    final testSessions = [
      ReadingSession(
        duaId: 'test_1',
        manzilNumber: 1,
        startTime: now.subtract(const Duration(days: 1, hours: 1)),
        endTime: now.subtract(const Duration(days: 1, minutes: 45)),
        readingDuration: const Duration(minutes: 15),
      ),
      ReadingSession(
        duaId: 'test_2',
        manzilNumber: 2,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 40)),
        readingDuration: const Duration(minutes: 20),
      ),
      ReadingSession(
        duaId: 'test_3',
        manzilNumber: 1,
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 20)),
        readingDuration: const Duration(minutes: 10),
      ),
    ];

    for (final session in testSessions) {
      await analyticsService.recordReadingSession(session);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test data added! Pull to refresh.')),
    );
  }

  Future<void> _clearAllData() async {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    final analyticsService = duaProvider.analyticsService;

    await analyticsService.clearAllData();
    await _loadAnalytics();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All analytics data cleared!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Reading Analytics',
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: textColor),
              tooltip: 'Clear All Data',
              onPressed: _clearAllData,
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: textColor),
              tooltip: 'Add Test Data',
              onPressed: _addTestData,
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsOverview(isDark, textColor, accentColor),
                      const SizedBox(height: 16),
                      _buildWeeklyChart(isDark),
                      const SizedBox(height: 16),
                      _buildManzilProgress(isDark, textColor, accentColor),
                      const SizedBox(height: 16),
                      _buildAchievements(isDark, textColor, accentColor),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatsOverview(bool isDark, Color textColor, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Current Streak',
            value: '$_currentStreak',
            subtitle: 'days',
            icon: Icons.local_fire_department,
            color: Colors.orange,
            isDark: isDark,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Time',
            value: '${_totalReadingTime.inHours}h',
            subtitle: '${_totalReadingTime.inMinutes % 60}m',
            icon: Icons.schedule,
            color: accentColor,
            isDark: isDark,
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textColor,
  }) {
    return GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(color: textColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
    return GlassCard(
      isDark: isDark,
      child: AnalyticsChart(weeklyStats: _weeklyStats),
    );
  }

  Widget _buildManzilProgress(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Manzil Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (index) {
            final manzilNumber = index + 1;
            final progress = _manzilProgress[manzilNumber] ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manzil $manzilNumber',
                        style: TextStyle(color: textColor),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: textColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements(bool isDark, Color textColor, Color accentColor) {
    final achievements = [
      Achievement(
        id: 'first_read',
        title: 'First Steps',
        description: 'Read your first dua',
        iconName: 'star',
        unlockedAt: DateTime.now(),
        isUnlocked: _totalReadingTime.inSeconds > 0,
      ),
      Achievement(
        id: 'five_minutes',
        title: 'Getting Started',
        description: 'Spent 5 minutes reading',
        iconName: 'timer',
        unlockedAt: DateTime.now(),
        isUnlocked: _totalReadingTime.inMinutes >= 5,
      ),
      Achievement(
        id: 'one_hour',
        title: 'Dedicated Reader',
        description: 'Spent 1 hour reading',
        iconName: 'schedule',
        unlockedAt: DateTime.now(),
        isUnlocked: _totalReadingTime.inHours >= 1,
      ),
    ];

    return GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) =>
                AchievementBadge(achievement: achievements[index]),
          ),
        ],
      ),
    );
  }
}
