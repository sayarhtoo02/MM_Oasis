import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../models/hadith_book.dart';
import '../services/hadith_service.dart';

class HadithProvider with ChangeNotifier {
  final HadithService _service = HadithService();

  HadithBook? _currentBook;
  List<Hadith> _currentHadiths = [];
  String _selectedBookKey = 'bukhari';
  String _selectedLanguage = 'my';
  int? _selectedChapterId;
  bool _isLoading = false;

  HadithBook? get currentBook => _currentBook;
  List<Hadith> get currentHadiths => _currentHadiths;
  String get selectedBookKey => _selectedBookKey;
  String get selectedLanguage => _selectedLanguage;
  int? get selectedChapterId => _selectedChapterId;
  bool get isLoading => _isLoading;

  Future<void> loadBook(String bookKey) async {
    _isLoading = true;
    _selectedBookKey = bookKey;
    notifyListeners();

    try {
      _currentBook = await _service.getBookMetadata(bookKey);
    } catch (e) {
      debugPrint('Error loading book: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChapter(int chapterId) async {
    _isLoading = true;
    _selectedChapterId = chapterId;
    notifyListeners();

    try {
      _currentHadiths = await _service.getHadithsByChapter(
        _selectedBookKey,
        chapterId,
      );
    } catch (e) {
      debugPrint('Error loading chapter: $e');
      _currentHadiths = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      notifyListeners();
    }
  }
}
