import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  NotificationService(this.notificationsPlugin) {
    tz.initializeTimeZones();
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_dua_channel',
      'Daily Dua Reminders',
      channelDescription: 'Reminders for daily duas',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDaily(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_dua_channel',
          'Daily Dua Reminders',
          channelDescription: 'Reminders for daily duas',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfDaily(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  Future<bool?> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final DarwinFlutterLocalNotificationsPlugin? iOSImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<DarwinFlutterLocalNotificationsPlugin>();

    bool? androidGranted = await androidImplementation?.requestNotificationsPermission();
    bool? iOSGranted = await iOSImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? false) || (iOSGranted ?? false);
  }
}
