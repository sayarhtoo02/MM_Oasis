import 'package:flutter/material.dart';
import '../../config/glass_theme.dart';
import '../../utils/haptic_feedback_helper.dart';

class GlassAppBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;

  const GlassAppBar({
    super.key,
    required this.title,
    required this.isDark,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = GlassTheme.text(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (automaticallyImplyLeading && Navigator.canPop(context))
            GestureDetector(
              onTap: () {
                HapticFeedbackHelper.lightImpact();
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),

          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
