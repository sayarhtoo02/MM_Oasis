import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/dua_provider.dart';
import '../models/widget_settings.dart';
import '../models/dua_model.dart';
import '../services/widget_service.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  bool _isWidgetSupported = false;

  @override
  void initState() {
    super.initState();
    _checkWidgetSupport();
  }

  Future<void> _checkWidgetSupport() async {
    final supported = await WidgetService.isWidgetSupported();
    if (mounted) {
      setState(() {
        _isWidgetSupported = supported;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, DuaProvider>(
      builder: (context, settingsProvider, duaProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final widgetSettings = settingsProvider.appSettings.widgetSettings;

        return GlassScaffold(
          title: 'Widget Settings',
          body: !_isWidgetSupported
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.widgets_outlined,
                        size: 64,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Widgets not supported on this device',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Lock Screen Widget Section
                    _buildSectionHeader(
                      'Lock Screen Widget',
                      textColor,
                      accentColor,
                    ),
                    GlassCard(
                      isDark: isDark,
                      borderRadius: 16,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'Enable Lock Screen Widget',
                            subtitle: 'Show favorite dua on lock screen',
                            value: widgetSettings.isLockScreenWidgetEnabled,
                            textColor: textColor,
                            accentColor: accentColor,
                            onChanged: (value) {
                              settingsProvider.setLockScreenWidgetEnabled(
                                value,
                              );
                            },
                          ),
                          if (widgetSettings.isLockScreenWidgetEnabled) ...[
                            Divider(color: textColor.withValues(alpha: 0.1)),
                            _buildDuaSelector(
                              title: 'Lock Screen Dua',
                              selectedDuaId: widgetSettings.lockScreenDuaId,
                              textColor: textColor,
                              accentColor: accentColor,
                              onDuaSelected: (duaId) {
                                settingsProvider.setLockScreenDua(duaId);
                              },
                              duaProvider: duaProvider,
                            ),
                            _buildDisplayModeSelector(
                              title: 'Display Mode',
                              selectedMode:
                                  widgetSettings.lockScreenDisplayMode,
                              textColor: textColor,
                              accentColor: accentColor,
                              onModeSelected: (mode) {
                                settingsProvider.setWidgetDisplayMode(
                                  mode,
                                  isLockScreen: true,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Home Screen Widget Section
                    _buildSectionHeader(
                      'Home Screen Widget',
                      textColor,
                      accentColor,
                    ),
                    GlassCard(
                      isDark: isDark,
                      borderRadius: 16,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'Enable Home Screen Widget',
                            subtitle: 'Add dua widget to home screen',
                            value: widgetSettings.isHomeScreenWidgetEnabled,
                            textColor: textColor,
                            accentColor: accentColor,
                            onChanged: (value) {
                              settingsProvider.setHomeScreenWidgetEnabled(
                                value,
                              );
                              if (value) {
                                _requestPinWidget();
                              }
                            },
                          ),
                          if (widgetSettings.isHomeScreenWidgetEnabled) ...[
                            Divider(color: textColor.withValues(alpha: 0.1)),
                            _buildDuaSelector(
                              title: 'Home Screen Dua',
                              selectedDuaId: widgetSettings.homeScreenDuaId,
                              textColor: textColor,
                              accentColor: accentColor,
                              onDuaSelected: (duaId) {
                                settingsProvider.setHomeScreenDua(duaId);
                              },
                              duaProvider: duaProvider,
                            ),
                            _buildDisplayModeSelector(
                              title: 'Display Mode',
                              selectedMode:
                                  widgetSettings.homeScreenDisplayMode,
                              textColor: textColor,
                              accentColor: accentColor,
                              onModeSelected: (mode) {
                                settingsProvider.setWidgetDisplayMode(mode);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Widget Language Section
                    _buildSectionHeader(
                      'Widget Language',
                      textColor,
                      accentColor,
                    ),
                    GlassCard(
                      isDark: isDark,
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      onTap: () => _showLanguageSelector(
                        context,
                        settingsProvider,
                        isDark,
                        textColor,
                        accentColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Translation Language',
                              style: TextStyle(color: textColor, fontSize: 16),
                            ),
                            Row(
                              children: [
                                Text(
                                  _getLanguageName(
                                    widgetSettings.preferredLanguage,
                                  ),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Actions Section
                    if (widgetSettings.isHomeScreenWidgetEnabled) ...[
                      _buildSectionHeader('Actions', textColor, accentColor),
                      GlassCard(
                        isDark: isDark,
                        borderRadius: 16,
                        padding: EdgeInsets.zero,
                        onTap: _requestPinWidget,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_to_home_screen,
                                color: accentColor,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add Widget to Home Screen',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Pin widget to your home screen',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: accentColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 16)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accentColor,
            inactiveThumbColor: textColor.withValues(alpha: 0.5),
            inactiveTrackColor: textColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaSelector({
    required String title,
    required String? selectedDuaId,
    required Color textColor,
    required Color accentColor,
    required Function(String) onDuaSelected,
    required DuaProvider duaProvider,
  }) {
    return InkWell(
      onTap: () => _showDuaSelector(
        context,
        onDuaSelected,
        duaProvider,
        textColor,
        accentColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 16)),
            Row(
              children: [
                Text(
                  selectedDuaId != null
                      ? _getDuaTitle(selectedDuaId, duaProvider)
                      : 'Select a dua',
                  style: TextStyle(color: accentColor, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector({
    required String title,
    required WidgetDisplayMode selectedMode,
    required Color textColor,
    required Color accentColor,
    required Function(WidgetDisplayMode) onModeSelected,
  }) {
    return InkWell(
      onTap: () => _showDisplayModeSelector(
        context,
        selectedMode,
        onModeSelected,
        textColor,
        accentColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 16)),
            Row(
              children: [
                Text(
                  _getDisplayModeName(selectedMode),
                  style: TextStyle(color: accentColor, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDuaTitle(String duaId, DuaProvider duaProvider) {
    final dua = duaProvider.allDuas.firstWhere(
      (d) => d.id == duaId,
      orElse: () => Dua(
        id: '',
        manzilNumber: 0,
        day: '',
        pageNumber: 0,
        arabicText: 'Unknown Dua',
        translations: Translations(urdu: '', english: '', burmese: ''),
        faida: Faida(),
      ),
    );
    return dua.arabicText.length > 20
        ? '${dua.arabicText.substring(0, 20)}...'
        : dua.arabicText;
  }

  String _getDisplayModeName(WidgetDisplayMode mode) {
    switch (mode) {
      case WidgetDisplayMode.arabicOnly:
        return 'Arabic Only';
      case WidgetDisplayMode.translationOnly:
        return 'Translation Only';
      case WidgetDisplayMode.arabicWithTranslation:
        return 'Arabic with Translation';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ur':
        return 'Urdu';
      case 'mm':
      case 'my':
        return 'Myanmar';
      default:
        return 'English';
    }
  }

  void _showDuaSelector(
    BuildContext context,
    Function(String) onDuaSelected,
    DuaProvider duaProvider,
    Color textColor,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: GlassTheme.background(
              Provider.of<SettingsProvider>(context).isDarkMode,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Dua',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: duaProvider.allDuas.length,
                  itemBuilder: (context, index) {
                    final dua = duaProvider.allDuas[index];
                    return ListTile(
                      title: Text(
                        dua.arabicText.length > 50
                            ? '${dua.arabicText.substring(0, 50)}...'
                            : dua.arabicText,
                        style: TextStyle(
                          fontFamily: 'Indopak',
                          letterSpacing: 0,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Manzil ${dua.manzilNumber} - ${dua.day}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () {
                        onDuaSelected(dua.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisplayModeSelector(
    BuildContext context,
    WidgetDisplayMode selectedMode,
    Function(WidgetDisplayMode) onModeSelected,
    Color textColor,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.background(
        Provider.of<SettingsProvider>(context, listen: false).isDarkMode,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Display Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...WidgetDisplayMode.values.map(
              (mode) => ListTile(
                title: Text(
                  _getDisplayModeName(mode),
                  style: TextStyle(color: textColor),
                ),
                leading: Radio<WidgetDisplayMode>(
                  value: mode,
                  groupValue: selectedMode,
                  activeColor: accentColor,
                  onChanged: (value) {
                    if (value != null) {
                      onModeSelected(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  onModeSelected(mode);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    SettingsProvider settingsProvider,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'ur', 'name': 'Urdu'},
      {'code': 'mm', 'name': 'Myanmar'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.background(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Widget Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map(
              (lang) => ListTile(
                title: Text(lang['name']!, style: TextStyle(color: textColor)),
                leading: Radio<String>(
                  value: lang['code']!,
                  groupValue: settingsProvider
                      .appSettings
                      .widgetSettings
                      .preferredLanguage,
                  activeColor: accentColor,
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.setWidgetLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  settingsProvider.setWidgetLanguage(lang['code']!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPinWidget() async {
    final success = await WidgetService.requestPinWidget();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Widget added to home screen successfully!'
                : 'Failed to add widget to home screen',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
