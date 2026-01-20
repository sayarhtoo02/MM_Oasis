import 'dart:convert';
import 'package:flutter/services.dart';

class TafseerService {
  static const String _basePath = 'assets/quran_data/tasfeer-ibn-kasir';

  /// Load Myanmar Tafseer for specific ayah
  static Future<List<TafseerItem>> getMyanmarTafseer(String ayahKey) async {
    try {
      // Find the correct part file containing this ayah
      final partFile = await _findPartFile(ayahKey, 'my-ibn-kasir');
      if (partFile == null) return [];

      final jsonString = await rootBundle.loadString(
        '$_basePath/my-ibn-kasir/$partFile',
      );
      final List<dynamic> data = json.decode(jsonString);

      return data
          .where((item) {
            final itemAyahKey = item['ayah_key']?.toString();
            final itemAyahKeys = item['ayah_keys']?.toString();

            return itemAyahKey == ayahKey ||
                (itemAyahKeys?.split(',').contains(ayahKey) == true);
          })
          .map((item) => TafseerItem.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load English Tafseer for specific ayah
  static Future<List<TafseerItem>> getEnglishTafseer(String ayahKey) async {
    try {
      final partFile = await _findPartFile(ayahKey, 'en-ibn-kasir');
      if (partFile == null) return [];

      final jsonString = await rootBundle.loadString(
        '$_basePath/en-ibn-kasir/$partFile',
      );
      final List<dynamic> data = json.decode(jsonString);

      return data
          .where((item) {
            final itemAyahKey = item['ayah_key']?.toString();
            final itemAyahKeys = item['ayah_keys']?.toString();

            return itemAyahKey == ayahKey ||
                (itemAyahKeys?.split(',').contains(ayahKey) == true);
          })
          .map((item) => TafseerItem.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Find which part file contains the ayah
  static Future<String?> _findPartFile(String ayahKey, String language) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final partFiles = manifestMap.keys
          .where(
            (key) =>
                key.contains('$_basePath/$language/part_') &&
                key.endsWith('.json'),
          )
          .map((key) => key.split('/').last)
          .toList();

      // Sort files numerically
      partFiles.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aNum.compareTo(bNum);
      });

      // Check files sequentially
      for (String partFile in partFiles) {
        try {
          final jsonString = await rootBundle.loadString(
            '$_basePath/$language/$partFile',
          );
          final List<dynamic> data = json.decode(jsonString);

          final hasAyah = data.any((item) {
            final itemAyahKey = item['ayah_key']?.toString();
            final itemAyahKeys = item['ayah_keys']?.toString();

            return itemAyahKey == ayahKey ||
                (itemAyahKeys?.split(',').contains(ayahKey) == true);
          });

          if (hasAyah) return partFile;
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Ignore error
    }
    return null;
  }
}

class TafseerItem {
  final String ayahKey;
  final String groupAyahKey;
  final String fromAyah;
  final String toAyah;
  final String ayahKeys;
  final String text;

  TafseerItem({
    required this.ayahKey,
    required this.groupAyahKey,
    required this.fromAyah,
    required this.toAyah,
    required this.ayahKeys,
    required this.text,
  });

  factory TafseerItem.fromJson(Map<String, dynamic> json) {
    return TafseerItem(
      ayahKey: json['ayah_key'] ?? '',
      groupAyahKey: json['group_ayah_key'] ?? '',
      fromAyah: json['from_ayah'] ?? '',
      toAyah: json['to_ayah'] ?? '',
      ayahKeys: json['ayah_keys'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
