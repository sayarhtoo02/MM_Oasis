import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';

class GlassUpdateDialog extends StatelessWidget {
  final String version;
  final String? releaseNotes;
  final bool forceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final VoidCallback onOpenBrowser;
  final bool isDownloading;
  final int downloadProgress;

  const GlassUpdateDialog({
    super.key,
    required this.version,
    this.releaseNotes,
    required this.forceUpdate,
    required this.onUpdate,
    required this.onLater,
    required this.onOpenBrowser,
    this.isDownloading = false,
    this.downloadProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);
    final goldColor = const Color(0xFFFFD700);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: GlassCard(
          borderRadius: 24,
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [goldColor, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Version
                Center(
                  child: Column(
                    children: [
                      Text(
                        'New Update Available',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Version $version',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Release Notes
                if (releaseNotes != null && releaseNotes!.isNotEmpty) ...[
                  Text(
                    'What\'s New:',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        releaseNotes!,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                if (isDownloading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Downloading...',
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                          Text(
                            '$downloadProgress%',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: downloadProgress / 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: onUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: onOpenBrowser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Open in Browser'),
                      ),
                      if (!forceUpdate) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: onLater,
                          style: TextButton.styleFrom(
                            foregroundColor: textColor.withValues(alpha: 0.6),
                          ),
                          child: const Text('Maybe Later'),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
