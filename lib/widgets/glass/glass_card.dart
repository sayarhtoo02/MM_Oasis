import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/glass_theme.dart';
import '../../providers/settings_provider.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;

  // New customization options
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double? blurStrength;

  // Backwards compatibility (ignored if provider is used, but kept for signature matching if needed elsewhere, though we removed isDark requirement)
  final bool? isDarkForce;

  GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    dynamic borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.gradientColors,
    this.borderColor,
    this.blurStrength,
    bool? isDarkForce,
    @Deprecated('Use isDarkForce or rely on SettingsProvider') bool? isDark,
  }) : isDarkForce = isDarkForce ?? isDark,
       borderRadius = borderRadius is num
           ? BorderRadius.circular(borderRadius.toDouble())
           : (borderRadius is BorderRadius ? borderRadius : null);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = isDarkForce ?? settings.isDarkMode;
        final radius = borderRadius ?? BorderRadius.circular(20);
        final border = borderColor ?? GlassTheme.glassBorder(isDark);
        final gradient = gradientColors ?? GlassTheme.glassGradient(isDark);
        final blur = blurStrength ?? 10.0;

        Widget cardContent = Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: border, width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: GlassTheme.glassShadow(isDark),
          ),
          child: child,
        );

        if (onTap != null) {
          cardContent = InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: cardContent,
          );
        }

        return Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }
}
