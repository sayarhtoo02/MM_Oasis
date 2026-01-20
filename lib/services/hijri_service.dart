class HijriService {
  static String getHijriDate() {
    final gregorian = DateTime.now();
    final hijri = _gregorianToHijri(gregorian);
    final monthName = _getHijriMonthName(hijri['month']!);
    return '${hijri['day']} $monthName ${hijri['year']}';
  }

  static Map<String, int> _gregorianToHijri(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;

    if (month < 3) {
      year -= 1;
      month += 12;
    }

    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd = (365.25 * (year + 4716)).floor() + (30.6001 * (month + 1)).floor() + day + b - 1524;

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() + (l / 5670).floor() * ((43 * l) / 15238).floor();
    l = l - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() - (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
    
    int hijriMonth = ((24 * l) / 709).floor();
    int hijriDay = l - ((709 * hijriMonth) / 24).floor();
    int hijriYear = 30 * n + j - 30;

    return {'day': hijriDay, 'month': hijriMonth, 'year': hijriYear};
  }

  static String _getHijriMonthName(int month) {
    const months = [
      'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban',
      'Ramadan', 'Shawwal', 'Dhul-Qadah', 'Dhul-Hijjah'
    ];
    return months[month - 1];
  }
}
