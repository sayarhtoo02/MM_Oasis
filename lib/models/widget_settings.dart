class WidgetSettings {
  final bool isLockScreenWidgetEnabled;
  final bool isHomeScreenWidgetEnabled;
  final String? lockScreenDuaId;
  final String? homeScreenDuaId;
  final WidgetDisplayMode lockScreenDisplayMode;
  final WidgetDisplayMode homeScreenDisplayMode;
  final bool showTranslation;
  final String preferredLanguage;

  WidgetSettings({
    this.isLockScreenWidgetEnabled = false,
    this.isHomeScreenWidgetEnabled = false,
    this.lockScreenDuaId,
    this.homeScreenDuaId,
    this.lockScreenDisplayMode = WidgetDisplayMode.arabicOnly,
    this.homeScreenDisplayMode = WidgetDisplayMode.arabicWithTranslation,
    this.showTranslation = true,
    this.preferredLanguage = 'mm',
  });

  WidgetSettings copyWith({
    bool? isLockScreenWidgetEnabled,
    bool? isHomeScreenWidgetEnabled,
    String? lockScreenDuaId,
    String? homeScreenDuaId,
    WidgetDisplayMode? lockScreenDisplayMode,
    WidgetDisplayMode? homeScreenDisplayMode,
    bool? showTranslation,
    String? preferredLanguage,
  }) {
    return WidgetSettings(
      isLockScreenWidgetEnabled: isLockScreenWidgetEnabled ?? this.isLockScreenWidgetEnabled,
      isHomeScreenWidgetEnabled: isHomeScreenWidgetEnabled ?? this.isHomeScreenWidgetEnabled,
      lockScreenDuaId: lockScreenDuaId ?? this.lockScreenDuaId,
      homeScreenDuaId: homeScreenDuaId ?? this.homeScreenDuaId,
      lockScreenDisplayMode: lockScreenDisplayMode ?? this.lockScreenDisplayMode,
      homeScreenDisplayMode: homeScreenDisplayMode ?? this.homeScreenDisplayMode,
      showTranslation: showTranslation ?? this.showTranslation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
        'isLockScreenWidgetEnabled': isLockScreenWidgetEnabled,
        'isHomeScreenWidgetEnabled': isHomeScreenWidgetEnabled,
        'lockScreenDuaId': lockScreenDuaId,
        'homeScreenDuaId': homeScreenDuaId,
        'lockScreenDisplayMode': lockScreenDisplayMode.name,
        'homeScreenDisplayMode': homeScreenDisplayMode.name,
        'showTranslation': showTranslation,
        'preferredLanguage': preferredLanguage,
      };

  factory WidgetSettings.fromJson(Map<String, dynamic> json) => WidgetSettings(
        isLockScreenWidgetEnabled: json['isLockScreenWidgetEnabled'] as bool? ?? false,
        isHomeScreenWidgetEnabled: json['isHomeScreenWidgetEnabled'] as bool? ?? false,
        lockScreenDuaId: json['lockScreenDuaId'] as String?,
        homeScreenDuaId: json['homeScreenDuaId'] as String?,
        lockScreenDisplayMode: WidgetDisplayMode.values.firstWhere(
          (e) => e.name == json['lockScreenDisplayMode'],
          orElse: () => WidgetDisplayMode.arabicOnly,
        ),
        homeScreenDisplayMode: WidgetDisplayMode.values.firstWhere(
          (e) => e.name == json['homeScreenDisplayMode'],
          orElse: () => WidgetDisplayMode.arabicWithTranslation,
        ),
        showTranslation: json['showTranslation'] as bool? ?? true,
        preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      );

  static WidgetSettings initial() => WidgetSettings();
}

enum WidgetDisplayMode {
  arabicOnly,
  translationOnly,
  arabicWithTranslation,
}
