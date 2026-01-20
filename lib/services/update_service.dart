import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

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
      if (!silent) {
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
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => AlertDialog(
        title: Text('Update Available: $version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes != null) ...[Text(notes), const SizedBox(height: 10)],
            const Text(
              'A new version of the app is available. Please update to continue.',
            ),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fallbackUrlLaunch(context, url);
            },
            child: const Text('Open in Browser'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpdate(context, url);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Updates'),
        content: const Text('You are using the latest version of the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpdate(BuildContext context, String url) async {
    if (Platform.isAndroid) {
      try {
        await _showProgressNotification(0);
        // Use ota_update for direct APK download and install
        // Note: The URL must be a direct link to the APK file
        OtaUpdate()
            .execute(url)
            .listen(
              (OtaEvent event) {
                if (event.status == OtaStatus.DOWNLOADING) {
                  final progress = int.tryParse(event.value ?? '0') ?? 0;
                  _showProgressNotification(progress);
                  debugPrint('Downloading: ${event.value}%');
                } else if (event.status == OtaStatus.INSTALLING) {
                  _cancelNotification();
                  debugPrint('Installing...');
                } else {
                  debugPrint('OTA Status: ${event.status}');
                }
              },
              onError: (e) {
                _cancelNotification();
                debugPrint('OTA Stream Error: $e');
                _handleUpdateError(context, url, e.toString());
              },
              onDone: () {
                // Note: onDone might not be called if installation takes over
                _cancelNotification();
              },
            );
      } catch (e) {
        await _cancelNotification();
        debugPrint('OTA Error: $e');
        _handleUpdateError(context, url, e.toString());
      }
    } else {
      // iOS or other platforms: just open the URL
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
