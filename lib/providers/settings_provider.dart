import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/models/app_settings.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/services/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _appSettings;
  final SettingsRepository _repository;

  SettingsProvider(this._repository) : _appSettings = AppSettings.initial() {
    _loadSettings();
  }

  AppSettings get appSettings => _appSettings;

  // Generic update method for any setting
  void updateSettings(AppSettings newSettings) {
    _appSettings = newSettings;
    notifyListeners();
    _repository.saveSettings(_appSettings);
  }

  // Specific setters for UI to interact with
  void setSelectedLanguage(String language) {
    updateSettings(_appSettings.copyWith(
      languageSettings: _appSettings.languageSettings.copyWith(selectedLanguage: language),
    ));
  }

  void setArabicFontSizeMultiplier(double multiplier) {
    updateSettings(_appSettings.copyWith(
      displaySettings: _appSettings.displaySettings.copyWith(arabicFontSizeMultiplier: multiplier),
    ));
  }

  void setTranslationFontSizeMultiplier(double multiplier) {
    updateSettings(_appSettings.copyWith(
      displaySettings: _appSettings.displaySettings.copyWith(translationFontSizeMultiplier: multiplier),
    ));
  }

  void setSelectedThemeMode(ThemeMode themeMode) {
    updateSettings(_appSettings.copyWith(
      displaySettings: _appSettings.displaySettings.copyWith(selectedThemeMode: themeMode),
    ));
  }


  void setLastReadDua(Dua dua) {
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(lastReadDua: dua),
    ));
  }

  void setManzilProgress(int manzilNumber, String duaId) {
    final updatedManzilProgress = Map<int, String>.from(_appSettings.duaPreferences.manzilProgress);
    updatedManzilProgress[manzilNumber] = duaId;
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(manzilProgress: updatedManzilProgress),
    ));
  }

  void toggleFavoriteDua(Dua dua) {
    final isFavorite = _appSettings.duaPreferences.favoriteDuas.any((d) => d.id == dua.id);
    List<Dua> updatedFavorites = List.from(_appSettings.duaPreferences.favoriteDuas);
    if (isFavorite) {
      updatedFavorites.removeWhere((d) => d.id == dua.id);
    } else {
      updatedFavorites.add(dua);
    }
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(favoriteDuas: updatedFavorites),
    ));
  }

  bool isDuaFavorite(Dua dua) {
    return _appSettings.duaPreferences.favoriteDuas.any((d) => d.id == dua.id);
  }

  Future<void> _loadSettings() async {
    _appSettings = await _repository.loadSettings();
    notifyListeners();
  }
}
