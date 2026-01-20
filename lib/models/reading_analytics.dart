class ReadingSession {
  final String duaId;
  final int manzilNumber;
  final DateTime startTime;
  final DateTime endTime;
  final Duration readingDuration;

  ReadingSession({
    required this.duaId,
    required this.manzilNumber,
    required this.startTime,
    required this.endTime,
    required this.readingDuration,
  });

  Map<String, dynamic> toJson() => {
        'duaId': duaId,
        'manzilNumber': manzilNumber,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'readingDuration': readingDuration.inSeconds,
      };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
        duaId: json['duaId'],
        manzilNumber: json['manzilNumber'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        readingDuration: Duration(seconds: json['readingDuration']),
      );
}

class DailyStats {
  final DateTime date;
  final int totalSessions;
  final Duration totalReadingTime;
  final Set<int> manzilsRead;
  final int duasCompleted;

  DailyStats({
    required this.date,
    required this.totalSessions,
    required this.totalReadingTime,
    required this.manzilsRead,
    required this.duasCompleted,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalSessions': totalSessions,
        'totalReadingTime': totalReadingTime.inSeconds,
        'manzilsRead': manzilsRead.toList(),
        'duasCompleted': duasCompleted,
      };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: DateTime.parse(json['date']),
        totalSessions: json['totalSessions'],
        totalReadingTime: Duration(seconds: json['totalReadingTime']),
        manzilsRead: Set<int>.from(json['manzilsRead']),
        duasCompleted: json['duasCompleted'],
      );
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    required this.isUnlocked,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconName': iconName,
        'unlockedAt': unlockedAt.toIso8601String(),
        'isUnlocked': isUnlocked,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        iconName: json['iconName'],
        unlockedAt: DateTime.parse(json['unlockedAt']),
        isUnlocked: json['isUnlocked'],
      );
}
