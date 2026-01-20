import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class ThemedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool enableGlassmorphism;

  const ThemedContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.enableGlassmorphism = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = backgroundColor ?? Theme.of(context).cardColor;

    if (enableGlassmorphism) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            margin: margin,
            decoration: BoxDecoration(
              color: defaultColor.withValues(alpha: isDark ? 0.7 : 0.9),
              borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
              border:
                  border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
              boxShadow:
                  boxShadow ??
                  [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: isDark
                          ? AppConstants.warmGoldAccent.withValues(alpha: 0.05)
                          : AppConstants.warmGoldAccent.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                      spreadRadius: 0,
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin,
      decoration: BoxDecoration(
        color: defaultColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        border: border,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
  }
}
