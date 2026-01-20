import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/dua_model.dart';
import '../models/reading_analytics.dart';
import '../services/analytics_service.dart';

class DuaProvider extends ChangeNotifier {
  List<Dua> _allDuas = [];
  bool _isLoaded = false;
  final AnalyticsService _analyticsService = AnalyticsService();
  DateTime? _sessionStartTime;

  List<Dua> get allDuas => _allDuas;

  Future<void> loadAllDuas() async {
    if (_isLoaded) {
      return; // Load only once
    }
    try {
      final String response = await rootBundle.loadString(
        'assets/munajat.json',
      );
      final List<dynamic> data = json.decode(response);
      _allDuas = data.map((json) => Dua.fromJson(json)).toList();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading duas: $e');
    }
  }

  void startReadingSession() {
    _sessionStartTime = DateTime.now();
  }

  Future<void> endReadingSession(Dua dua) async {
    if (_sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!);

    if (duration.inSeconds > 5) {
      // Only track sessions longer than 5 seconds
      final session = ReadingSession(
        duaId: dua.id,
        manzilNumber: dua.manzilNumber,
        startTime: _sessionStartTime!,
        endTime: endTime,
        readingDuration: duration,
      );

      try {
        await _analyticsService.recordReadingSession(session);
      } catch (e) {
        debugPrint('Analytics: Error recording session: $e');
      }
    }

    _sessionStartTime = null;
  }

  AnalyticsService get analyticsService => _analyticsService;
}
