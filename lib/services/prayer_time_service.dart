import 'package:adhan/adhan.dart';

class PrayerTimeService {
  static const double _defaultLatitude = 21.4225; // Yangon, Myanmar
  static const double _defaultLongitude = 96.0836;

  PrayerTimeService();

  // Calculate prayer times for a given date and location
  PrayerTimes calculatePrayerTimes({
    required DateTime date,
    double latitude = _defaultLatitude,
    double longitude = _defaultLongitude,
    CalculationMethod? method,
    Madhab asrMethod = Madhab.hanafi,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final params = method?.getParameters() ?? CalculationParameters(method: CalculationMethod.other, fajrAngle: 18.0, ishaAngle: 17.0);
    params.madhab = asrMethod;
    final dateComponents = DateComponents(date.year, date.month, date.day);
    
    return PrayerTimes(coordinates, dateComponents, params);
  }

  // Get next prayer time from current time
  Map<String, dynamic> getNextPrayer({
    DateTime? currentTime,
    double latitude = _defaultLatitude,
    double longitude = _defaultLongitude,
    CalculationMethod? method,
    Madhab asrMethod = Madhab.hanafi,
  }) {
    currentTime ??= DateTime.now();
    final prayerTimes = calculatePrayerTimes(
      date: currentTime,
      latitude: latitude,
      longitude: longitude,
      method: method,
      asrMethod: asrMethod,
    );

    final prayers = [
      {'name': 'fajr', 'time': prayerTimes.fajr},
      {'name': 'dhuhr', 'time': prayerTimes.dhuhr},
      {'name': 'asr', 'time': prayerTimes.asr},
      {'name': 'maghrib', 'time': prayerTimes.maghrib},
      {'name': 'isha', 'time': prayerTimes.isha},
    ];

    for (final prayer in prayers) {
      final prayerTime = prayer['time'] as DateTime;
      if (prayerTime.isAfter(currentTime)) {
        return {
          'name': prayer['name'],
          'time': prayerTime,
          'timeRemaining': prayerTime.difference(currentTime),
        };
      }
    }

    // If no prayer found today, get tomorrow's Fajr
    final tomorrowPrayerTimes = calculatePrayerTimes(
      date: currentTime.add(const Duration(days: 1)),
      latitude: latitude,
      longitude: longitude,
      method: method,
      asrMethod: asrMethod,
    );

    return {
      'name': 'fajr',
      'time': tomorrowPrayerTimes.fajr,
      'timeRemaining': tomorrowPrayerTimes.fajr.difference(currentTime),
    };
  }

  // Get prayer times formatted as strings
  Map<String, String> getPrayerTimesFormatted({
    DateTime? date,
    double latitude = _defaultLatitude,
    double longitude = _defaultLongitude,
    CalculationMethod? method,
    Madhab asrMethod = Madhab.hanafi,
    bool use24Hour = false,
  }) {
    date ??= DateTime.now();
    
    final prayerTimes = calculatePrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      method: method,
      asrMethod: asrMethod,
    );

    return {
      'fajr': _formatTime(prayerTimes.fajr, use24Hour),
      'sunrise': _formatTime(prayerTimes.sunrise, use24Hour),
      'dhuhr': _formatTime(prayerTimes.dhuhr, use24Hour),
      'asr': _formatTime(prayerTimes.asr, use24Hour),
      'maghrib': _formatTime(prayerTimes.maghrib, use24Hour),
      'isha': _formatTime(prayerTimes.isha, use24Hour),
    };
  }

  String _formatTime(DateTime time, bool use24Hour) {
    if (use24Hour) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }
}
