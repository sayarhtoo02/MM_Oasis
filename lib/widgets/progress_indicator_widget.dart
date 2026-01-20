import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final String title;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${currentIndex + 1}/$totalCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.warmGoldAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.warmGoldAccent,
            ),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}
