import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/notification_service.dart';
import 'package:munajat_e_maqbool_app/main.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationService _notificationService;
  TimeOfDay? _selectedTime;
  bool _isReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(flutterLocalNotificationsPlugin);
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final reminderHour = settingsProvider.appSettings.reminderHour;
    final reminderMinute = settingsProvider.appSettings.reminderMinute;
    final isEnabled = settingsProvider.appSettings.isReminderEnabled;

    setState(() {
      _isReminderEnabled = isEnabled;
      if (reminderHour != null && reminderMinute != null) {
        _selectedTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
      }
    });
  }

  Future<void> _selectTime(
    BuildContext context,
    bool isDark,
    Color accentColor,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await _updateReminder();
    }
  }

  void _toggleReminder(bool value) async {
    setState(() {
      _isReminderEnabled = value;
    });
    if (value && _selectedTime == null) {
      _selectedTime = TimeOfDay.now();
    }
    await _updateReminder();
  }

  Future<void> _updateReminder() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    if (_isReminderEnabled && _selectedTime != null) {
      try {
        final bool granted = await _notificationService.requestPermissions();
        if (granted) {
          await _notificationService.scheduleDailyReminder(
            hour: _selectedTime!.hour,
            minute: _selectedTime!.minute,
          );

          await settingsProvider.setReminderSettings(
            isEnabled: true,
            hour: _selectedTime!.hour,
            minute: _selectedTime!.minute,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Daily reminder set for ${_selectedTime!.format(context)}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _isReminderEnabled = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permissions required'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isReminderEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      await _notificationService.cancelDailyReminder();
      await settingsProvider.setReminderSettings(
        isEnabled: false,
        hour: null,
        minute: null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily reminder cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Daily Reminders',
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reminder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get reminded to recite Munajat-e-Maqbool daily',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable Daily Reminder',
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                        Switch(
                          value: _isReminderEnabled,
                          onChanged: _toggleReminder,
                          activeThumbColor: accentColor,
                          inactiveThumbColor: textColor.withValues(alpha: 0.5),
                          inactiveTrackColor: textColor.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    if (_isReminderEnabled) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectTime(context, isDark, accentColor),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reminder Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _selectedTime?.format(context) ?? 'Select Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test if notifications are working',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _notificationService.showTestNotification();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Send Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              GlassCard(
                isDark: isDark,
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Make sure notifications are enabled in Android settings\n'
                      '• Add this app to battery optimization whitelist\n'
                      '• Turn off Do Not Disturb mode to receive reminders\n'
                      '• Reminders will repeat daily at the selected time',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
