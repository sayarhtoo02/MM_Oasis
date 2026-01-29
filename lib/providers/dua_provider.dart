import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/dua_model.dart';
import '../models/reading_analytics.dart';
import '../services/analytics_service.dart';
import '../services/database/oasismm_database.dart';

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
      final rows = await OasisMMDatabase.getMunajat();
      _allDuas = rows.map((row) => _duaFromRow(row)).toList();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading duas: $e');
    }
  }

  Dua _duaFromRow(Map<String, dynamic> row) {
    // Try to parse from data_json if available
    if (row['data_json'] != null) {
      try {
        final jsonData = json.decode(row['data_json'] as String);
        return Dua.fromJson(jsonData);
      } catch (_) {}
    }

    return Dua(
      id: row['id']?.toString() ?? '',
      manzilNumber: row['manzil_number'] ?? 1,
      day: row['day'] ?? '',
      pageNumber: row['page_number'] ?? 1,
      source: row['source'],
      arabicText: row['arabic_text'] ?? '',
      translations: Translations(
        urdu: row['translation_urdu'] ?? '',
        english: row['translation'] ?? '',
        burmese: row['translation_burmese'] ?? '',
      ),
      faida: Faida(
        urdu: row['faida_urdu'],
        english: row['faida_english'],
        burmese: row['faida_burmese'],
      ),
      audioUrl: row['audio_url'],
      notes: row['notes'],
    );
  }

  void startReadingSession() {
    _sessionStartTime = DateTime.now();
  }

  Future<void> endReadingSession(Dua dua) async {
    if (_sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!);

    if (duration.inSeconds > 5) {
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
