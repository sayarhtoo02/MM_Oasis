import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/notification_service.dart';
import 'package:munajat_e_maqbool_app/main.dart'; // For flutterLocalNotificationsPlugin

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
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
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateReminder();
    }
  }

  void _toggleReminder(bool value) {
    setState(() {
      _isReminderEnabled = value;
    });
    _updateReminder();
  }

  Future<void> _updateReminder() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (_isReminderEnabled && _selectedTime != null) {
      // Request permissions if not granted
      final bool? granted = await _notificationService.requestPermissions();
      if (granted == true) {
        await _notificationService.scheduleDailyNotification(
          id: 0, // Unique ID for the daily reminder
          title: 'Daily Dua Reminder',
          body: 'It\'s time for your daily Munajat-e-Maqbool recitation!',
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
          payload: 'daily_dua_reminder',
        );
        settingsProvider.setReminderSettings(
          isEnabled: true,
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily reminder set!')),
        );
      } else {
        // If permissions not granted, disable reminder in UI and settings
        setState(() {
          _isReminderEnabled = false;
        });
        settingsProvider.setReminderSettings(
          isEnabled: false,
          hour: null,
          minute: null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permissions denied. Cannot set reminder.')),
        );
      }
    } else {
      await _notificationService.cancelNotification(0); // Cancel the daily reminder
      settingsProvider.setReminderSettings(
        isEnabled: false,
        hour: null,
        minute: null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reminder cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enable Daily Reminder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: _isReminderEnabled,
                    onChanged: _toggleReminder,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isReminderEnabled)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: InkWell(
                onTap: () => _selectTime(context),
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reminder Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _selectedTime?.format(context) ?? 'Select Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
