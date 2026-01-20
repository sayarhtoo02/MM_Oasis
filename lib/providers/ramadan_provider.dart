import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RamadanProvider with ChangeNotifier {
  // Fasting status: Map of date string (YYYY-MM-DD) to status (fasted, missed, none)
  Map<String, String> _fastingStatus = {};

  // Daily deeds: Map of date string to list of completed deed IDs
  Map<String, List<String>> _dailyDeeds = {};

  // Zakat settings
  double _goldPrice = 0.0;
  double _silverPrice = 0.0;
  String _currency = 'USD';

  // Time offsets (in minutes)
  int _sehriOffset = -3;
  int _iftarOffset = 3;

  RamadanProvider() {
    _loadData();
  }

  Map<String, String> get fastingStatus => _fastingStatus;
  Map<String, List<String>> get dailyDeeds => _dailyDeeds;
  double get goldPrice => _goldPrice;
  double get silverPrice => _silverPrice;
  String get currency => _currency;
  int get sehriOffset => _sehriOffset;
  int get iftarOffset => _iftarOffset;

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load fasting status
    final fastingJson = prefs.getString('ramadan_fasting_status');
    if (fastingJson != null) {
      _fastingStatus = Map<String, String>.from(jsonDecode(fastingJson));
    }

    // Load daily deeds
    final deedsJson = prefs.getString('ramadan_daily_deeds');
    if (deedsJson != null) {
      final decoded = jsonDecode(deedsJson) as Map<String, dynamic>;
      _dailyDeeds = decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
    }

    // Load Zakat settings
    _goldPrice = prefs.getDouble('zakat_gold_price') ?? 0.0;
    _silverPrice = prefs.getDouble('zakat_silver_price') ?? 0.0;
    _currency = prefs.getString('zakat_currency') ?? 'USD';

    // Load time offsets
    _sehriOffset = prefs.getInt('ramadan_sehri_offset') ?? -3;
    _iftarOffset = prefs.getInt('ramadan_iftar_offset') ?? 3;

    notifyListeners();
  }

  Future<void> setFastingStatus(DateTime date, String status) async {
    final dateKey = _getDateKey(date);
    _fastingStatus[dateKey] = status;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ramadan_fasting_status', jsonEncode(_fastingStatus));
  }

  String getFastingStatus(DateTime date) {
    return _fastingStatus[_getDateKey(date)] ?? 'none';
  }

  Future<void> toggleDeed(DateTime date, String deedId) async {
    final dateKey = _getDateKey(date);
    final deeds = _dailyDeeds[dateKey] ?? [];

    if (deeds.contains(deedId)) {
      deeds.remove(deedId);
    } else {
      deeds.add(deedId);
    }

    _dailyDeeds[dateKey] = deeds;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ramadan_daily_deeds', jsonEncode(_dailyDeeds));
  }

  bool isDeedCompleted(DateTime date, String deedId) {
    final deeds = _dailyDeeds[_getDateKey(date)];
    return deeds != null && deeds.contains(deedId);
  }

  Future<void> updateZakatSettings({
    double? goldPrice,
    double? silverPrice,
    String? currency,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (goldPrice != null) {
      _goldPrice = goldPrice;
      await prefs.setDouble('zakat_gold_price', goldPrice);
    }

    if (silverPrice != null) {
      _silverPrice = silverPrice;
      await prefs.setDouble('zakat_silver_price', silverPrice);
    }

    if (currency != null) {
      _currency = currency;
      await prefs.setString('zakat_currency', currency);
    }

    notifyListeners();
  }

  Future<void> updateTimeOffsets({int? sehri, int? iftar}) async {
    final prefs = await SharedPreferences.getInstance();

    if (sehri != null) {
      _sehriOffset = sehri;
      await prefs.setInt('ramadan_sehri_offset', sehri);
    }

    if (iftar != null) {
      _iftarOffset = iftar;
      await prefs.setInt('ramadan_iftar_offset', iftar);
    }

    notifyListeners();
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
