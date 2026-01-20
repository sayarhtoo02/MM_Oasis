import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/dua_model.dart';
import '../providers/settings_provider.dart';
import '../providers/dua_provider.dart';
import '../widgets/dua_detail_components/dua_content_display.dart';
import '../widgets/dua_detail_components/audio_player_controls.dart';
import '../widgets/dua_detail_components/dua_detail_app_bar_actions.dart';
import '../widgets/dua_detail_components/dua_audio_player_manager.dart';
import '../widgets/floating_action_menu.dart';
import '../utils/haptic_feedback_helper.dart';
import '../services/reading_stats_service.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DuaDetailScreen extends StatefulWidget {
  final Dua initialDua;
  final List<Dua> manzilDuas;

  const DuaDetailScreen({
    super.key,
    required this.initialDua,
    required this.manzilDuas,
  });

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  late TextEditingController _notesController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    int initialIndex = widget.manzilDuas.indexWhere(
      (dua) => dua.id == widget.initialDua.id,
    );
    _currentPageIndex = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentPageIndex);

    _notesController = TextEditingController();
    _scrollController = ScrollController();
    _loadDuaNote(widget.manzilDuas[_currentPageIndex].id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionForCurrentDua();
    });
  }

  @override
  void dispose() {
    _endSessionForCurrentDua();
    _pageController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSessionForCurrentDua() async {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    duaProvider.startReadingSession();
    final statsService = ReadingStatsService();
    await statsService.updateReadingStreak();
    await statsService.incrementDuasRead();
  }

  void _endSessionForCurrentDua() {
    final duaProvider = Provider.of<DuaProvider>(context, listen: false);
    duaProvider.endReadingSession(widget.manzilDuas[_currentPageIndex]);
  }

  void _loadDuaNote(String duaId) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final note = settingsProvider.getDuaNote(duaId);
    _notesController.text = note ?? '';
  }

  void _saveDuaNote(String duaId, String note) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    settingsProvider.setDuaNote(duaId, note);
  }

  void _copyDuaText(Dua dua, String selectedLanguage) {
    final String translationText = dua.translations.getTranslationText(
      selectedLanguage,
    );
    final String textToCopy =
        'Arabic: ${dua.arabicText}\n\nTranslation: $translationText\n\nSource: ${dua.source}';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dua text copied to clipboard!')),
    );
  }

  void _shareDuaText(Dua dua, String selectedLanguage) {
    final String translationText = dua.translations.getTranslationText(
      selectedLanguage,
    );
    final String textToShare =
        'Munajat-e-Maqbool\n\nArabic: ${dua.arabicText}\n\nTranslation: $translationText\n\nSource: ${dua.source}\n\n#MunajatEMaqboolApp';
    // ignore: deprecated_member_use
    Share.share(textToShare);
  }

  void _showWidgetOptions(Dua dua, SettingsProvider settingsProvider) {
    final isDark = settingsProvider.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent for Glass effect
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: GlassTheme.background(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: GlassTheme.glassBorder(isDark)),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Widget',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: GlassTheme.text(isDark)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.lock_outline, color: GlassTheme.text(isDark)),
              title: Text(
                'Set as Lock Screen Dua',
                style: TextStyle(color: GlassTheme.text(isDark)),
              ),
              subtitle: Text(
                'Show this dua on lock screen notification',
                style: TextStyle(
                  color: GlassTheme.text(isDark).withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                settingsProvider.setLockScreenDua(dua.id);
                settingsProvider.setLockScreenWidgetEnabled(true);
                settingsProvider.updateWidgetsWithDua(dua);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dua set as lock screen notification!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.home_outlined,
                color: GlassTheme.text(isDark),
              ),
              title: Text(
                'Set as Home Screen Widget',
                style: TextStyle(color: GlassTheme.text(isDark)),
              ),
              subtitle: Text(
                'Show this dua on your home screen',
                style: TextStyle(
                  color: GlassTheme.text(isDark).withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                settingsProvider.setHomeScreenDua(dua.id);
                settingsProvider.setHomeScreenWidgetEnabled(true);
                settingsProvider.updateWidgetsWithDua(dua);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Dua added to home screen widget! Add widget from home screen.',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final selectedLanguage =
            settingsProvider.appSettings.languageSettings.selectedLanguage;
        final currentDua = widget.manzilDuas[_currentPageIndex];
        final isReadingMode =
            settingsProvider.appSettings.displaySettings.isReadingMode;
        final isNightMode =
            settingsProvider.appSettings.displaySettings.isNightReadingMode;
        final isDark = settingsProvider.isDarkMode;

        if (isReadingMode) {
          // Immersive Reading Mode
          return Scaffold(
            backgroundColor: isNightMode
                ? const Color(0xFF1A1A1A)
                : GlassTheme.background(false),
            body: _buildPageView(
              settingsProvider,
              currentDua,
              isReadingMode,
              isNightMode,
              selectedLanguage,
              isDark,
            ),
          );
        } else {
          // Standard Glass UI Mode
          return GlassScaffold(
            title: currentDua.day,
            actions: [
              IconButton(
                icon: Icon(
                  settingsProvider.appSettings.displaySettings.isReadingMode
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: GlassTheme.text(isDark),
                ),
                tooltip: 'Reading Mode',
                onPressed: () {
                  HapticFeedbackHelper.buttonPress();
                  settingsProvider.setReadingMode(
                    !settingsProvider.appSettings.displaySettings.isReadingMode,
                  );
                },
              ),
              DuaDetailAppBarActions(
                currentDua: currentDua,
                selectedLanguage: selectedLanguage,
                onCopyDuaText: _copyDuaText,
                onShareDuaText: _shareDuaText,
              ),
            ],
            body: _buildPageView(
              settingsProvider,
              currentDua,
              isReadingMode,
              isNightMode,
              selectedLanguage,
              isDark,
            ),
            floatingActionButton: FloatingActionMenu(
              isBookmarked: settingsProvider.isDuaFavorite(currentDua),
              onBookmark: () {
                HapticFeedbackHelper.bookmarkToggle();
                settingsProvider.toggleFavoriteDua(currentDua);
              },
              onShare: () {
                HapticFeedbackHelper.buttonPress();
                _shareDuaText(currentDua, selectedLanguage);
              },
              onAddToWidget: () {
                HapticFeedbackHelper.buttonPress();
                _showWidgetOptions(currentDua, settingsProvider);
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildPageView(
    SettingsProvider settingsProvider,
    Dua currentDua,
    bool isReadingMode,
    bool isNightMode,
    String selectedLanguage,
    bool isDark,
  ) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      itemCount: widget.manzilDuas.length,
      onPageChanged: (index) {
        HapticFeedbackHelper.swipeGesture();
        _endSessionForCurrentDua();
        setState(() {
          _currentPageIndex = index;
        });
        final nextDua = widget.manzilDuas[index];
        settingsProvider.setLastReadDua(nextDua);
        settingsProvider.setManzilProgress(nextDua.manzilNumber, nextDua.id);
        _loadDuaNote(nextDua.id);
        _startSessionForCurrentDua();
      },
      itemBuilder: (context, index) {
        final dua = widget.manzilDuas[index];
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isReadingMode ? 24.0 : 20.0,
            vertical: isReadingMode ? 48.0 : 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isReadingMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isNightMode ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () {
                        HapticFeedbackHelper.buttonPress();
                        settingsProvider.setReadingMode(false);
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isNightMode ? Icons.light_mode : Icons.dark_mode,
                            color: isNightMode ? Colors.amber : Colors.black87,
                          ),
                          onPressed: () {
                            HapticFeedbackHelper.buttonPress();
                            settingsProvider.setNightReadingMode(!isNightMode);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Wrap DuaContentDisplay in GlassCard if NOT in reading mode for better aesthetic?
              // DuaContentDisplay likely has its own styling. Let's keep it as is but wrap in transparent container if needed.
              // For now, just render it.
              DuaContentDisplay(dua: dua, selectedLanguage: selectedLanguage),

              if (!isReadingMode) ...[
                const SizedBox(height: 25),
                // Audio Player in a Glass Card
                GlassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: DuaAudioPlayerManager(
                      currentDua: dua,
                      builder:
                          (
                            playerState,
                            duration,
                            position,
                            onPlayPausePressed,
                            onSliderChanged,
                            isLooping,
                            onToggleLoop,
                            playbackSpeed,
                            onSpeedChanged,
                          ) {
                            return AudioPlayerControls(
                              playerState: playerState,
                              duration: duration,
                              position: position,
                              onPlayPausePressed: onPlayPausePressed,
                              onSliderChanged: onSliderChanged,
                              isLooping: isLooping,
                              onToggleLoop: onToggleLoop,
                              playbackSpeed: playbackSpeed,
                              onSpeedChanged: onSpeedChanged,
                            );
                          },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.text(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Add your personal notes here...',
                    hintStyle: TextStyle(
                      color: GlassTheme.text(isDark).withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: GlassTheme.glassBorder(isDark),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: GlassTheme.glassBorder(isDark),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: GlassTheme.accent(isDark)),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.white24,
                    contentPadding: const EdgeInsets.all(16.0),
                  ),
                  style: TextStyle(color: GlassTheme.text(isDark)),
                  onChanged: (text) {
                    _saveDuaNote(dua.id, text);
                  },
                ),
                // Add extra padding at bottom to avoid FAB overlap
                const SizedBox(height: 80),
              ],
            ],
          ),
        );
      },
    );
  }
}
