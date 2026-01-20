import 'package:flutter/material.dart';
import '../models/reading_analytics.dart';
import '../config/app_constants.dart';

class AnalyticsChart extends StatelessWidget {
  final List<DailyStats> weeklyStats;

  const AnalyticsChart({super.key, required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Reading Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.warmGoldAccent,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyStats.asMap().entries.map((entry) {
                final stats = entry.value;
                final height = _calculateBarHeight(stats.totalReadingTime);

                return _buildBar(
                  context,
                  height: height,
                  day: _getDayLabel(stats.date),
                  minutes: stats.totalReadingTime.inMinutes,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context, {
    required double height,
    required String day,
    required int minutes,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (minutes > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppConstants.warmGoldAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${minutes}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  double _calculateBarHeight(Duration duration) {
    const maxHeight = 120.0;
    const maxMinutes = 60; // 1 hour max for scaling

    final minutes = duration.inMinutes;
    return (minutes / maxMinutes * maxHeight).clamp(4.0, maxHeight);
  }

  String _getDayLabel(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }
}
