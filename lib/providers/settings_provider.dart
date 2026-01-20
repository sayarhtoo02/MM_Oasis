import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/models/app_settings.dart';
import 'package:munajat_e_maqbool_app/models/custom_collection.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/models/reminder_settings.dart';
import 'package:munajat_e_maqbool_app/models/widget_settings.dart';
import 'package:munajat_e_maqbool_app/services/settings_repository.dart';
import 'package:munajat_e_maqbool_app/services/notification_service.dart';
import 'package:munajat_e_maqbool_app/services/widget_service.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart'; // Import new constants
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _appSettings;
  final SettingsRepository _repository;
  final NotificationService? _notificationService;

  SettingsProvider(this._repository, [this._notificationService])
    : _appSettings = AppSettings.initial() {
    _loadSettings();
  }
  // ... (lines 22-113 omitted)

  void setAccentColor(AppAccentColor accentColor) {
    updateSettings(_appSettings.copyWith(accentColor: accentColor));
    GlassTheme.setAccent(accentColor.color);
  }

  // ... (lines 118-454 omitted)

  Future<void> _loadSettings() async {
    _appSettings = await _repository.loadSettings();
    GlassTheme.setAccent(_appSettings.accentColor.color);
    notifyListeners();
    // Schedule notifications after loading settings
    _scheduleNotifications();
  }

  AppSettings get appSettings => _appSettings;
  NotificationService get notificationService => _notificationService!;

  bool get isDarkMode {
    if (_appSettings.themeMode == AppThemeMode.dark) return true;
    if (_appSettings.themeMode == AppThemeMode.light) return false;
    // Default to system
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Generic update method for any setting
  void updateSettings(AppSettings newSettings) {
    _appSettings = newSettings;
    notifyListeners();
    _repository.saveSettings(_appSettings);
  }

  // Specific setters for UI to interact with
  void setSelectedLanguage(String language) {
    updateSettings(
      _appSettings.copyWith(
        languageSettings: _appSettings.languageSettings.copyWith(
          selectedLanguage: language,
        ),
      ),
    );
  }

  void setArabicFontSizeMultiplier(double multiplier) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          arabicFontSizeMultiplier: multiplier,
        ),
      ),
    );
  }

  void setTranslationFontSizeMultiplier(double multiplier) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          translationFontSizeMultiplier: multiplier,
        ),
      ),
    );
  }

  void setReadingMode(bool enabled) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          isReadingMode: enabled,
        ),
      ),
    );
  }

  void setNightReadingMode(bool enabled) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          isNightReadingMode: enabled,
        ),
      ),
    );
  }

  void setAutoScrollEnabled(bool enabled) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          autoScrollEnabled: enabled,
        ),
      ),
    );
  }

  void setLineSpacing(double spacing) {
    updateSettings(
      _appSettings.copyWith(
        displaySettings: _appSettings.displaySettings.copyWith(
          lineSpacing: spacing,
        ),
      ),
    );
  }

  void setThemeMode(AppThemeMode themeMode) {
    updateSettings(_appSettings.copyWith(themeMode: themeMode));
  }

  void setLastReadDua(Dua dua) {
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(lastReadDua: dua),
      ),
    );
    // Update widgets with the last read dua
    updateWidgetsWithDua(dua);
  }

  void setManzilProgress(int manzilNumber, String duaId) {
    final updatedManzilProgress = Map<int, String>.from(
      _appSettings.duaPreferences.manzilProgress,
    );
    updatedManzilProgress[manzilNumber] = duaId;
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(
          manzilProgress: updatedManzilProgress,
        ),
      ),
    );
  }

  void toggleFavoriteDua(Dua dua) {
    final isFavorite = _appSettings.duaPreferences.favoriteDuas.any(
      (d) => d.id == dua.id,
    );
    List<Dua> updatedFavorites = List.from(
      _appSettings.duaPreferences.favoriteDuas,
    );
    if (isFavorite) {
      updatedFavorites.removeWhere((d) => d.id == dua.id);
    } else {
      updatedFavorites.add(dua);
    }
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(
          favoriteDuas: updatedFavorites,
        ),
      ),
    );
  }

  Future<void> setReminderSettings({
    required bool isEnabled,
    int? hour,
    int? minute,
  }) async {
    updateSettings(
      _appSettings.copyWith(
        isReminderEnabled: isEnabled,
        reminderHour: hour,
        reminderMinute: minute,
      ),
    );
  }

  void addCustomCollection(CustomCollection collection) {
    final updatedCollections = List<CustomCollection>.from(
      _appSettings.duaPreferences.customCollections,
    );
    updatedCollections.add(collection);
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(
          customCollections: updatedCollections,
        ),
      ),
    );
  }

  void removeCustomCollection(String collectionId) {
    final updatedCollections = List<CustomCollection>.from(
      _appSettings.duaPreferences.customCollections,
    );
    updatedCollections.removeWhere((c) => c.id == collectionId);
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(
          customCollections: updatedCollections,
        ),
      ),
    );
  }

  void updateCustomCollection(CustomCollection updatedCollection) {
    final updatedCollections = List<CustomCollection>.from(
      _appSettings.duaPreferences.customCollections,
    );
    final index = updatedCollections.indexWhere(
      (c) => c.id == updatedCollection.id,
    );
    if (index != -1) {
      updatedCollections[index] = updatedCollection;
      updateSettings(
        _appSettings.copyWith(
          duaPreferences: _appSettings.duaPreferences.copyWith(
            customCollections: updatedCollections,
          ),
        ),
      );
    }
  }

  void addDuaToCustomCollection(String collectionId, String duaId) {
    final updatedCollections = List<CustomCollection>.from(
      _appSettings.duaPreferences.customCollections,
    );
    final index = updatedCollections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = updatedCollections[index];
      if (!collection.duaIds.contains(duaId)) {
        final updatedDuaIds = List<String>.from(collection.duaIds)..add(duaId);
        updatedCollections[index] = collection.copyWith(duaIds: updatedDuaIds);
        updateSettings(
          _appSettings.copyWith(
            duaPreferences: _appSettings.duaPreferences.copyWith(
              customCollections: updatedCollections,
            ),
          ),
        );
      }
    }
  }

  void removeDuaFromCustomCollection(String collectionId, String duaId) {
    final updatedCollections = List<CustomCollection>.from(
      _appSettings.duaPreferences.customCollections,
    );
    final index = updatedCollections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = updatedCollections[index];
      if (collection.duaIds.contains(duaId)) {
        final updatedDuaIds = List<String>.from(collection.duaIds)
          ..remove(duaId);
        updatedCollections[index] = collection.copyWith(duaIds: updatedDuaIds);
        updateSettings(
          _appSettings.copyWith(
            duaPreferences: _appSettings.duaPreferences.copyWith(
              customCollections: updatedCollections,
            ),
          ),
        );
      }
    }
  }

  void setDuaNote(String duaId, String note) {
    final updatedNotes = Map<String, String>.from(
      _appSettings.duaPreferences.duaNotes,
    );
    if (note.isEmpty) {
      updatedNotes.remove(duaId); // Remove note if empty
    } else {
      updatedNotes[duaId] = note;
    }
    updateSettings(
      _appSettings.copyWith(
        duaPreferences: _appSettings.duaPreferences.copyWith(
          duaNotes: updatedNotes,
        ),
      ),
    );
  }

  String? getDuaNote(String duaId) {
    return _appSettings.duaPreferences.duaNotes[duaId];
  }

  bool isDuaFavorite(Dua dua) {
    return _appSettings.duaPreferences.favoriteDuas.any((d) => d.id == dua.id);
  }

  // Reminder management methods
  void addReminderSchedule(ReminderSchedule schedule) {
    final updatedSchedules = List<ReminderSchedule>.from(
      _appSettings.reminderSchedules,
    );
    updatedSchedules.add(schedule);
    updateSettings(_appSettings.copyWith(reminderSchedules: updatedSchedules));
    _scheduleNotifications();
  }

  void updateReminderSchedule(ReminderSchedule updatedSchedule) {
    final updatedSchedules = List<ReminderSchedule>.from(
      _appSettings.reminderSchedules,
    );
    final index = updatedSchedules.indexWhere(
      (s) => s.id == updatedSchedule.id,
    );
    if (index != -1) {
      updatedSchedules[index] = updatedSchedule;
      updateSettings(
        _appSettings.copyWith(reminderSchedules: updatedSchedules),
      );
      _scheduleNotifications();
    }
  }

  void removeReminderSchedule(int scheduleId) {
    final updatedSchedules = List<ReminderSchedule>.from(
      _appSettings.reminderSchedules,
    );
    updatedSchedules.removeWhere((s) => s.id == scheduleId);
    updateSettings(_appSettings.copyWith(reminderSchedules: updatedSchedules));
    _notificationService?.cancelDailyReminder();
  }

  void toggleReminderSchedule(int scheduleId, bool enabled) {
    final updatedSchedules = List<ReminderSchedule>.from(
      _appSettings.reminderSchedules,
    );
    final index = updatedSchedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      updatedSchedules[index] = updatedSchedules[index].copyWith(
        isEnabled: enabled,
      );
      updateSettings(
        _appSettings.copyWith(reminderSchedules: updatedSchedules),
      );
      if (enabled) {
        _scheduleNotifications();
      } else {
        _notificationService?.cancelDailyReminder();
      }
    }
  }

  void updateNotificationPreferences(NotificationPreferences preferences) {
    updateSettings(_appSettings.copyWith(notificationPreferences: preferences));
  }

  // Schedule prayer time reminders (placeholder - not implemented in current notification service)
  Future<void> schedulePrayerTimeReminders({
    double? latitude,
    double? longitude,
    double? timezone,
  }) async {
    // TODO: Implement prayer time reminders when needed
  }

  // Schedule streak reminder (placeholder - not implemented in current notification service)
  Future<void> checkAndScheduleStreakReminder(int daysMissed) async {
    // TODO: Implement streak reminders when needed
  }

  // Smart suggestion based on reading patterns (placeholder - not implemented in current notification service)
  Future<void> sendSmartSuggestion(String suggestion) async {
    // TODO: Implement smart suggestions when needed
  }

  // Widget settings methods
  void updateWidgetSettings(WidgetSettings widgetSettings) {
    updateSettings(_appSettings.copyWith(widgetSettings: widgetSettings));
  }

  void setLockScreenWidgetEnabled(bool enabled) {
    final updatedWidgetSettings = _appSettings.widgetSettings.copyWith(
      isLockScreenWidgetEnabled: enabled,
    );
    updateWidgetSettings(updatedWidgetSettings);
  }

  void setHomeScreenWidgetEnabled(bool enabled) {
    final updatedWidgetSettings = _appSettings.widgetSettings.copyWith(
      isHomeScreenWidgetEnabled: enabled,
    );
    updateWidgetSettings(updatedWidgetSettings);
  }

  void setLockScreenDua(String duaId) {
    final updatedWidgetSettings = _appSettings.widgetSettings.copyWith(
      lockScreenDuaId: duaId,
    );
    updateWidgetSettings(updatedWidgetSettings);
  }

  void setHomeScreenDua(String duaId) {
    final updatedWidgetSettings = _appSettings.widgetSettings.copyWith(
      homeScreenDuaId: duaId,
    );
    updateWidgetSettings(updatedWidgetSettings);
  }

  void setWidgetDisplayMode(
    WidgetDisplayMode mode, {
    bool isLockScreen = false,
  }) {
    final updatedWidgetSettings = isLockScreen
        ? _appSettings.widgetSettings.copyWith(lockScreenDisplayMode: mode)
        : _appSettings.widgetSettings.copyWith(homeScreenDisplayMode: mode);
    updateWidgetSettings(updatedWidgetSettings);
  }

  void setWidgetLanguage(String languageCode) {
    final updatedWidgetSettings = _appSettings.widgetSettings.copyWith(
      preferredLanguage: languageCode,
    );
    updateWidgetSettings(updatedWidgetSettings);
    // Update widget with last read dua to reflect language change
    if (_appSettings.duaPreferences.lastReadDua != null) {
      updateWidgetsWithDua(_appSettings.duaPreferences.lastReadDua!);
    }
  }

  Future<void> updateWidgetsWithDua(Dua dua) async {
    try {
      if (_appSettings.widgetSettings.isLockScreenWidgetEnabled) {
        await WidgetService.updateLockScreenWidget(
          dua: dua,
          settings: _appSettings.widgetSettings,
        );
      }
      if (_appSettings.widgetSettings.isHomeScreenWidgetEnabled) {
        await WidgetService.updateHomeScreenWidget(
          dua: dua,
          settings: _appSettings.widgetSettings,
        );
      }
    } catch (e) {
      // Ignore error
    }
  }

  void _scheduleNotifications() {
    // Schedule daily reminder if enabled
    if (_appSettings.isReminderEnabled &&
        _appSettings.reminderHour != null &&
        _appSettings.reminderMinute != null) {
      _notificationService?.scheduleDailyReminder(
        hour: _appSettings.reminderHour!,
        minute: _appSettings.reminderMinute!,
      );
    }
  }
}
