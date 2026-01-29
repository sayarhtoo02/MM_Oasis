import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_update_dialog.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';

class UpdateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const int _notificationId = 888;
  static const String _channelId = 'app_update';

  UpdateService() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showProgressNotification(int progress) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          'App Updates',
          channelDescription: 'Download progress for app updates',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          autoCancel: false,
        );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      _notificationId,
      'Downloading Update',
      '$progress%',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelNotification() async {
    await _notificationsPlugin.cancel(_notificationId);
  }

  Future<void> checkForUpdates(
    BuildContext context, {
    bool silent = false,
  }) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Fetch latest version from Supabase
      final response = await _supabase
          .schema('munajat_app')
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (!context.mounted) return;
        if (!silent) _showNoUpdateDialog(context);
        return;
      }

      final latestVersionCode = response['version_code'] as int;
      final latestVersionName = response['version_name'] as String;
      final downloadUrl = response['download_url'] as String;
      final releaseNotes = response['release_notes'] as String?;
      final isForceUpdate = response['force_update'] as bool? ?? false;

      if (latestVersionCode > currentVersionCode) {
        if (!context.mounted) return;
        _showUpdateDialog(
          context,
          latestVersionName,
          releaseNotes,
          downloadUrl,
          isForceUpdate,
        );
      } else {
        if (!context.mounted) return;
        if (!silent) _showNoUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for updates: $e')),
        );
      }
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    String version,
    String? notes,
    String url,
    bool forceUpdate,
  ) {
    // ValueNotifier for reactive UI updates
    // progress: -1 (not started), 0-100 (downloading)
    final ValueNotifier<int> progressNotifier = ValueNotifier<int>(-1);

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) => ValueListenableBuilder<int>(
        valueListenable: progressNotifier,
        builder: (context, progress, child) {
          final isDownloading = progress >= 0;
          return GlassUpdateDialog(
            version: version,
            releaseNotes: notes,
            forceUpdate: forceUpdate,
            isDownloading: isDownloading,
            downloadProgress: progress,
            onUpdate: () {
              // Start update locally
              _performUpdate(context, url, progressNotifier);
            },
            onLater: () => Navigator.pop(context),
            onOpenBrowser: () {
              Navigator.pop(context);
              _fallbackUrlLaunch(context, url);
            },
          );
        },
      ),
    );
  }

  void _showNoUpdateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'No Updates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.text(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are using the latest version of the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GlassTheme.text(isDark).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.accent(isDark),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    String url,
    ValueNotifier<int> progressNotifier,
  ) async {
    if (Platform.isAndroid) {
      try {
        progressNotifier.value = 0; // Start loading state
        await _showProgressNotification(0);

        OtaUpdate()
            .execute(url)
            .listen(
              (OtaEvent event) {
                if (event.status == OtaStatus.DOWNLOADING) {
                  final progress = int.tryParse(event.value ?? '0') ?? 0;
                  progressNotifier.value = progress;
                  _showProgressNotification(progress);
                } else if (event.status == OtaStatus.INSTALLING) {
                  _cancelNotification();
                  // Optionally close dialog or show "Installing..."
                } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
                  // Handle download error gracefully
                  _cancelNotification();
                  debugPrint('OTA Download Error: ${event.value}');
                  if (context.mounted) {
                    Navigator.pop(context);
                    _handleUpdateError(
                      context,
                      url,
                      'Download failed. Please try again or download from browser.',
                    );
                  }
                } else {
                  debugPrint('OTA Status: ${event.status}');
                }
              },
              onError: (e) {
                _cancelNotification();
                debugPrint('OTA Stream Error: $e');
                if (context.mounted) {
                  Navigator.pop(context);
                  _handleUpdateError(context, url, e.toString());
                }
              },
              onDone: () {
                _cancelNotification();
              },
            );
      } catch (e) {
        await _cancelNotification();
        debugPrint('OTA Error: $e');
        if (context.mounted) {
          _handleUpdateError(context, url, e.toString());
          Navigator.pop(context);
        }
      }
    } else {
      // iOS or fallback
      Navigator.pop(context);
      _fallbackUrlLaunch(context, url);
    }
  }

  void _handleUpdateError(BuildContext context, String url, String error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $error. Opening in browser...'),
          duration: const Duration(seconds: 5),
        ),
      );
      _fallbackUrlLaunch(context, url);
    }
  }

  Future<void> _fallbackUrlLaunch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open update link.')),
        );
      }
    }
  }
}
