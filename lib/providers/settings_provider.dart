import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/models/app_settings.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/services/settings_repository.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart'; // Import new constants

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

  void setThemeMode(AppThemeMode themeMode) {
    updateSettings(_appSettings.copyWith(
      themeMode: themeMode,
    ));
  }

  void setAccentColor(AppAccentColor accentColor) {
    updateSettings(_appSettings.copyWith(
      accentColor: accentColor,
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

  void setReminderSettings({required bool isEnabled, int? hour, int? minute}) {
    updateSettings(_appSettings.copyWith(
      isReminderEnabled: isEnabled,
      reminderHour: hour,
      reminderMinute: minute,
    ));
  }

  void addCustomCollection(CustomCollection collection) {
    final updatedCollections = List<CustomCollection>.from(_appSettings.duaPreferences.customCollections);
    updatedCollections.add(collection);
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(customCollections: updatedCollections),
    ));
  }

  void removeCustomCollection(String collectionId) {
    final updatedCollections = List<CustomCollection>.from(_appSettings.duaPreferences.customCollections);
    updatedCollections.removeWhere((c) => c.id == collectionId);
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(customCollections: updatedCollections),
    ));
  }

  void updateCustomCollection(CustomCollection updatedCollection) {
    final updatedCollections = List<CustomCollection>.from(_appSettings.duaPreferences.customCollections);
    final index = updatedCollections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      updatedCollections[index] = updatedCollection;
      updateSettings(_appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(customCollections: updatedCollections),
      ));
    }
  }

  void addDuaToCustomCollection(String collectionId, String duaId) {
    final updatedCollections = List<CustomCollection>.from(_appSettings.duaPreferences.customCollections);
    final index = updatedCollections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = updatedCollections[index];
      if (!collection.duaIds.contains(duaId)) {
        final updatedDuaIds = List<String>.from(collection.duaIds)..add(duaId);
        updatedCollections[index] = collection.copyWith(duaIds: updatedDuaIds);
        updateSettings(_appSettings.copyWith(
          duaPreferences: _appSettings.duaPreferences.copyWith(customCollections: updatedCollections),
        ));
      }
    }
  }

  void removeDuaFromCustomCollection(String collectionId, String duaId) {
    final updatedCollections = List<CustomCollection>.from(_appSettings.duaPreferences.customCollections);
    final index = updatedCollections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = updatedCollections[index];
      if (collection.duaIds.contains(duaId)) {
        final updatedDuaIds = List<String>.from(collection.duaIds)..remove(duaId);
        updatedCollections[index] = collection.copyWith(duaIds: updatedDuaIds);
        updateSettings(_appSettings.copyWith(
          duaPreferences: _appSettings.duaPreferences.copyWith(customCollections: updatedCollections),
        ));
      }
    }
  }

  void setDuaNote(String duaId, String note) {
    final updatedNotes = Map<String, String>.from(_appSettings.duaPreferences.duaNotes);
    if (note.isEmpty) {
      updatedNotes.remove(duaId); // Remove note if empty
    } else {
      updatedNotes[duaId] = note;
    }
    updateSettings(_appSettings.copyWith(
      duaPreferences: _appSettings.duaPreferences.copyWith(duaNotes: updatedNotes),
    ));
  }

  String? getDuaNote(String duaId) {
    return _appSettings.duaPreferences.duaNotes[duaId];
  }

  bool isDuaFavorite(Dua dua) {
    return _appSettings.duaPreferences.favoriteDuas.any((d) => d.id == dua.id);
  }

  Future<void> _loadSettings() async {
    _appSettings = await _repository.loadSettings();
    notifyListeners();
  }
}
