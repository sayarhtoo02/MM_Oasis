import 'package:flutter/material.dart';
import '../models/reading_analytics.dart';
import '../config/app_constants.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: achievement.isUnlocked
              ? [
                  AppConstants.warmGoldAccent,
                  AppConstants.warmGoldAccent.withValues(alpha: 0.8),
                ]
              : [Colors.grey.shade400, Colors.grey.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: achievement.isUnlocked
                ? AppConstants.warmGoldAccent.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconData(achievement.iconName),
            size: 32,
            color: achievement.isUnlocked ? Colors.white : Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: achievement.isUnlocked
                  ? Colors.white
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: achievement.isUnlocked
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'schedule':
        return Icons.schedule;
      case 'military_tech':
        return Icons.military_tech;
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }
}
