import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/glass_theme.dart';
import '../../providers/settings_provider.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final String? label;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.onPressed,
    this.child = const SizedBox.shrink(),
    this.icon,
    this.label,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  factory GlassButton.icon({
    required VoidCallback? onPressed,
    required Widget icon,
    required Widget label,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassButton(
      onPressed: onPressed,
      icon: icon,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
      padding: padding,
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final radius = borderRadius ?? BorderRadius.circular(12);

        // Buttons should pop more than cards
        final bg =
            backgroundColor ?? GlassTheme.accent(isDark).withValues(alpha: 0.3);
        final border = GlassTheme.glassBorder(isDark).withValues(alpha: 0.5);
        final textCol = textColor ?? GlassTheme.text(isDark);

        // improved gradient logic
        final gradientColors = backgroundColor != null
            ? [
                backgroundColor!.withValues(alpha: 0.8),
                backgroundColor!.withValues(alpha: 0.6),
              ]
            : [bg, bg.withValues(alpha: 0.15)];

        Widget content;
        if (icon != null && label == null && child is SizedBox) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon!, const SizedBox(width: 8), child],
          );
        } else if (icon != null && label != null) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon!, const SizedBox(width: 8), Text(label!)],
          );
        } else if (label != null) {
          content = Center(child: Text(label!));
        } else if (icon != null) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon!, const SizedBox(width: 8), child],
          );
        } else {
          content = Center(child: child);
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: border, width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? Colors.black).withValues(
                  alpha: 0.15,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding:
                        padding ??
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: textCol,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize ?? 16,
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: textCol, size: 20),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
