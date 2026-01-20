import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.color,
    this.padding,
    this.margin,
    this.elevation,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? theme.cardTheme.margin,
      child: Material(
        color: Colors.transparent,
        elevation: elevation ?? theme.cardTheme.elevation ?? 4,
        shadowColor: theme.cardTheme.shadowColor,
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
            BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius
                  as BorderRadius? ??
              BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? theme.cardTheme.color) : null,
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (color ?? theme.cardTheme.color ?? Colors.white),
                      (color ?? theme.cardTheme.color ?? Colors.white)
                          .withValues(alpha: 0.95),
                    ],
                  ),
              borderRadius:
                  (theme.cardTheme.shape as RoundedRectangleBorder?)
                      ?.borderRadius ??
                  BorderRadius.circular(16),
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
