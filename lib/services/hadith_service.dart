import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hadith.dart';
import '../models/hadith_book.dart';

class HadithService {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  final Map<String, Map<String, dynamic>> _cache = {};

  static const Map<String, String> bookNames = {
    'bukhari': 'Sahih al Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abu Dawud',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'nasai': "Sunan an-Nasa'i",
    'ibnmajah': 'Sunan Ibn Majah',
    'malik': 'Muwatta Malik',
    'ahmed': 'Musnad Ahmed',
    'darimi': 'Sunan Darimi',
  };

  Future<HadithBook> getBookMetadata(String bookKey) async {
    final cacheKey = '${bookKey}_metadata';

    if (_cache.containsKey(cacheKey)) {
      return HadithBook.fromJson(_cache[cacheKey]!);
    }

    final path = 'assets/hadits_data/$bookKey.json';
    final jsonString = await rootBundle.loadString(path);
    final data = json.decode(jsonString);

    _cache[cacheKey] = data;
    return HadithBook.fromJson(data);
  }

  Future<List<Hadith>> getHadithsByChapter(
    String bookKey,
    int chapterId,
  ) async {
    try {
      final path = 'assets/hadits_data/$bookKey.json';
      // Optimization: In a real app, we might want to cache this or read partially.
      // For now, since we already likely loaded it for metadata, we can reuse if cached,
      // but getBookMetadata caches the whole JSON map, so we can just use that if available.

      final cacheKey = '${bookKey}_metadata';
      Map<String, dynamic> data;

      if (_cache.containsKey(cacheKey)) {
        data = _cache[cacheKey]!;
      } else {
        final jsonString = await rootBundle.loadString(path);
        data = json.decode(jsonString);
        _cache[cacheKey] = data;
      }

      final allHadiths = (data['hadiths'] as List)
          .map((h) => Hadith.fromJson(h))
          .toList();

      final filtered = allHadiths
          .where((h) => h.chapterId == chapterId)
          .toList();

      return filtered;
    } catch (e) {
      return [];
    }
  }

  Future<Hadith?> getHadithByNumber(
    String bookKey,
    dynamic hadithNumber,
  ) async {
    try {
      final cacheKey = '${bookKey}_metadata';
      Map<String, dynamic> data;

      if (_cache.containsKey(cacheKey)) {
        data = _cache[cacheKey]!;
      } else {
        final path = 'assets/hadits_data/$bookKey.json';
        final jsonString = await rootBundle.loadString(path);
        data = json.decode(jsonString);
        _cache[cacheKey] = data;
      }

      final hadiths = (data['hadiths'] as List)
          .map((h) => Hadith.fromJson(h))
          .toList();

      final searchStr = hadithNumber.toString().trim();
      // Regex to match the number optionally followed by letters (e.g. 1245 matches 1245a, 1245b)
      final regex = RegExp('^$searchStr[a-z]*\$', caseSensitive: false);

      try {
        return hadiths.firstWhere((h) {
          final id = h.idInBook.toString();
          return id == searchStr || regex.hasMatch(id);
        });
      } catch (_) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
