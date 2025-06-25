import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? children;
  final VoidCallback? onTap;

  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    this.children,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withAlpha((0.3 * 255).round()), width: 1),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha((0.2 * 255).round()),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: colorScheme.primary),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (children != null && children!.isNotEmpty) ...[
                Divider(height: 30, thickness: 1.5, color: colorScheme.primary.withAlpha((0.5 * 255).round())),
                ...children!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
