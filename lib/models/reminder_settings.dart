class ReminderSchedule {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isEnabled;
  final ReminderType type;
  final List<int> weekdays; // 1-7 (Monday-Sunday)

  const ReminderSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.type = ReminderType.daily,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  ReminderSchedule copyWith({
    int? id,
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? isEnabled,
    ReminderType? type,
    List<int>? weekdays,
  }) {
    return ReminderSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
        'type': type.name,
        'weekdays': weekdays,
      };

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) => ReminderSchedule(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        isEnabled: json['isEnabled'] as bool? ?? true,
        type: ReminderType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ReminderType.daily,
        ),
        weekdays: List<int>.from(json['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      );
}

enum ReminderType {
  daily,
  weekly,
  custom,
}

class NotificationPreferences {
  final bool enableSound;
  final bool enableVibration;
  final String soundPath;
  final int streakReminderDays;
  final bool enableStreakReminders;

  const NotificationPreferences({
    this.enableSound = true,
    this.enableVibration = true,
    this.soundPath = 'default',
    this.streakReminderDays = 3,
    this.enableStreakReminders = true,
  });

  NotificationPreferences copyWith({
    bool? enableSound,
    bool? enableVibration,
    String? soundPath,
    int? streakReminderDays,
    bool? enableStreakReminders,
  }) {
    return NotificationPreferences(
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      soundPath: soundPath ?? this.soundPath,
      streakReminderDays: streakReminderDays ?? this.streakReminderDays,
      enableStreakReminders: enableStreakReminders ?? this.enableStreakReminders,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableSound': enableSound,
        'enableVibration': enableVibration,
        'soundPath': soundPath,
        'streakReminderDays': streakReminderDays,
        'enableStreakReminders': enableStreakReminders,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => NotificationPreferences(
        enableSound: json['enableSound'] as bool? ?? true,
        enableVibration: json['enableVibration'] as bool? ?? true,
        soundPath: json['soundPath'] as String? ?? 'default',
        streakReminderDays: json['streakReminderDays'] as int? ?? 3,
        enableStreakReminders: json['enableStreakReminders'] as bool? ?? true,
      );

  static NotificationPreferences initial() => const NotificationPreferences();
}
