import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final Widget? prefixIcon;
  final bool isDark;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.prefixIcon,
    required this.isDark,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = GlassTheme.text(isDark);
    final hintColor = textColor.withValues(alpha: 0.5);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      maxLines: isPassword ? 1 : maxLines,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon:
            prefixIcon ?? (icon != null ? Icon(icon, color: hintColor) : null),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GlassTheme.accent(isDark), width: 1.5),
        ),
      ),
    );
  }
}
