import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TafseerPreferencesService {
  static const String _fontSizeKey = 'tafseer_font_size';
  static const String _lineHeightKey = 'tafseer_line_height';
  static const String _backgroundColorKey = 'tafseer_background_color';
  static const String _textColorKey = 'tafseer_text_color';
  static const String _languageKey = 'tafseer_language';
  static const String _bookmarksKey = 'tafseer_bookmarks';

  // Default values
  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.8;
  static const int defaultBackgroundColor = 0xFFFFFFFF; // White
  static const int defaultTextColor = 0xFF000000; // Black
  static const String defaultLanguage = 'my';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Font Size
  static Future<void> setFontSize(double fontSize) async {
    await init();
    await _prefs!.setDouble(_fontSizeKey, fontSize);
  }

  static Future<double> getFontSize() async {
    await init();
    return _prefs!.getDouble(_fontSizeKey) ?? defaultFontSize;
  }

  // Line Height
  static Future<void> setLineHeight(double lineHeight) async {
    await init();
    await _prefs!.setDouble(_lineHeightKey, lineHeight);
  }

  static Future<double> getLineHeight() async {
    await init();
    return _prefs!.getDouble(_lineHeightKey) ?? defaultLineHeight;
  }

  // Background Color
  static Future<void> setBackgroundColor(Color color) async {
    await init();
    await _prefs!.setInt(_backgroundColorKey, color.toARGB32());
  }

  static Future<Color> getBackgroundColor() async {
    await init();
    final colorValue =
        _prefs!.getInt(_backgroundColorKey) ?? defaultBackgroundColor;
    return Color(colorValue);
  }

  // Text Color
  static Future<void> setTextColor(Color color) async {
    await init();
    await _prefs!.setInt(_textColorKey, color.toARGB32());
  }

  static Future<Color> getTextColor() async {
    await init();
    final colorValue = _prefs!.getInt(_textColorKey) ?? defaultTextColor;
    return Color(colorValue);
  }

  // Language
  static Future<void> setLanguage(String language) async {
    await init();
    await _prefs!.setString(_languageKey, language);
  }

  static Future<String> getLanguage() async {
    await init();
    return _prefs!.getString(_languageKey) ?? defaultLanguage;
  }

  // Bookmarks
  static Future<void> addBookmark(String ayahKey) async {
    await init();
    final bookmarks = await getBookmarks();
    if (!bookmarks.contains(ayahKey)) {
      bookmarks.add(ayahKey);
      await _prefs!.setStringList(_bookmarksKey, bookmarks);
    }
  }

  static Future<void> removeBookmark(String ayahKey) async {
    await init();
    final bookmarks = await getBookmarks();
    bookmarks.remove(ayahKey);
    await _prefs!.setStringList(_bookmarksKey, bookmarks);
  }

  static Future<List<String>> getBookmarks() async {
    await init();
    return _prefs!.getStringList(_bookmarksKey) ?? [];
  }

  static Future<bool> isBookmarked(String ayahKey) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains(ayahKey);
  }

  // Reading Theme Presets
  static const Map<String, Map<String, dynamic>> readingThemes = {
    'light': {
      'backgroundColor': 0xFFFFFFFF,
      'textColor': 0xFF000000,
      'name': 'Light',
    },
    'sepia': {
      'backgroundColor': 0xFFF5F5DC,
      'textColor': 0xFF5D4037,
      'name': 'Sepia',
    },
    'dark': {
      'backgroundColor': 0xFF1E1E1E,
      'textColor': 0xFFE0E0E0,
      'name': 'Dark',
    },
    'green': {
      'backgroundColor': 0xFFE8F5E8,
      'textColor': 0xFF2E7D32,
      'name': 'Green',
    },
  };

  static Future<void> applyTheme(String themeName) async {
    final theme = readingThemes[themeName];
    if (theme != null) {
      await setBackgroundColor(Color(theme['backgroundColor']));
      await setTextColor(Color(theme['textColor']));
    }
  }

  // Reset to defaults
  static Future<void> resetToDefaults() async {
    await init();
    await _prefs!.remove(_fontSizeKey);
    await _prefs!.remove(_lineHeightKey);
    await _prefs!.remove(_backgroundColorKey);
    await _prefs!.remove(_textColorKey);
    await _prefs!.remove(_languageKey);
  }

  // Export/Import settings
  static Future<Map<String, dynamic>> exportSettings() async {
    return {
      'fontSize': await getFontSize(),
      'lineHeight': await getLineHeight(),
      'backgroundColor': (await getBackgroundColor()).toARGB32(),
      'textColor': (await getTextColor()).toARGB32(),
      'language': await getLanguage(),
      'bookmarks': await getBookmarks(),
    };
  }

  static Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['fontSize'] != null) {
      await setFontSize(settings['fontSize']);
    }
    if (settings['lineHeight'] != null) {
      await setLineHeight(settings['lineHeight']);
    }
    if (settings['backgroundColor'] != null) {
      await setBackgroundColor(Color(settings['backgroundColor']));
    }
    if (settings['textColor'] != null) {
      await setTextColor(Color(settings['textColor']));
    }
    if (settings['language'] != null) {
      await setLanguage(settings['language']);
    }
    if (settings['bookmarks'] != null) {
      await _prefs!.setStringList(
        _bookmarksKey,
        List<String>.from(settings['bookmarks']),
      );
    }
  }
}
