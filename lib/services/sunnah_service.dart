import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:munajat_e_maqbool_app/models/sunnah_collection_model.dart';
import 'package:munajat_e_maqbool_app/models/book_info_model.dart';

class SunnahService {
  Future<BookInfo?> getBookInfo() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/sunnah collection/book_info.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return BookInfo.fromJson(jsonMap);
    } catch (e) {
      print('Error loading book info: $e');
      return null;
    }
  }

  Future<List<SunnahChapter>> getAllChapters() async {
    List<String> chapterFiles = [];

    // Attempt 1: Load via AssetManifest.json
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      chapterFiles = manifestMap.keys.where((key) {
        // Decode URI component to handle spaces (e.g., %20)
        final decodedKey = Uri.decodeComponent(key);
        return decodedKey.contains('sunnah collection') &&
            decodedKey.contains('chapter_') &&
            decodedKey.endsWith('.json');
      }).toList();

      print('Found ${chapterFiles.length} chapters via AssetManifest');
    } catch (e) {
      print('AssetManifest.json load failed or no chapters found there: $e');
      // Continue to fallback
    }

    // Attempt 2: Fallback Manual Loop if manifest returned no files
    if (chapterFiles.isEmpty) {
      print('Using fallback loop to load chapters...');
      // We loop through 1 to 50 as a reasonable range for chapters
      // Assuming maximum 50 chapters for now
      for (int i = 1; i <= 50; i++) {
        // Try with direct path first
        final path = 'assets/sunnah collection/chapter_$i.json';
        try {
          // Just check if we can load it
          await rootBundle.loadString(path);
          chapterFiles.add(path);
        } catch (_) {
          // If direct path fails, it might be due to spaces, try encoding
          // But rootBundle.loadString usually expects the key exactly as in pubspec
        }
      }
      print('Found ${chapterFiles.length} chapters via fallback loop');
    }

    if (chapterFiles.isEmpty) {
      return [];
    }

    // Sort files numerically by chapter id extracted from filename
    chapterFiles.sort((a, b) {
      final idA = _extractChapterId(a);
      final idB = _extractChapterId(b);
      return idA.compareTo(idB);
    });

    List<SunnahChapter> chapters = [];
    for (String filePath in chapterFiles) {
      try {
        final String jsonString = await rootBundle.loadString(filePath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        chapters.add(SunnahChapter.fromJson(jsonMap));
      } catch (e) {
        print('Error loading chapter $filePath: $e');
      }
    }

    return chapters;
  }

  int _extractChapterId(String filePath) {
    // Expected format: assets/sunnah collection/chapter_1.json
    try {
      // Decode in case it's encoded
      final decodedPath = Uri.decodeComponent(filePath);
      final fileName = decodedPath.split('/').last; // chapter_1.json
      final namePart = fileName.replaceAll('.json', ''); // chapter_1
      final idPart = namePart.split('_').last; // 1
      return int.parse(idPart);
    } catch (e) {
      return 0;
    }
  }
}
