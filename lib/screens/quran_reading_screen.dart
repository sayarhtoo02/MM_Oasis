import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:munajat_e_maqbool_app/screens/surah_info_screen.dart';
import '../models/quran_surah.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import 'mashaf_view.dart';
import 'translation_view.dart';

enum ViewMode { mashaf, translation }

class QuranReadingScreen extends StatefulWidget {
  final int initialSurahNumber;
  final int? initialAyahNumber;
  final int? initialPageNumber;

  const QuranReadingScreen({
    super.key,
    required this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialPageNumber,
  });

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool _isImmersive = false;
  late ViewMode _viewMode;
  late int _currentPage;
  late int _currentSurahNumber;
  int? _currentAyahNumber;
  QuranSurah? _currentSurah;
  Map<String, dynamic>? _selectedAyah;
  int? _targetTranslationAyah;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.initialSurahNumber;
    _currentAyahNumber = widget.initialAyahNumber;
    _currentPage = widget.initialPageNumber ?? 1;

    // Initialize View Mode based on provider preference
    final provider = context.read<QuranProvider>();
    _viewMode = provider.isMashafMode ? ViewMode.mashaf : ViewMode.translation;

    // Initialize PageController
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSurah();
      _initializeNavigation();
    });
  }

  /// Initialize navigation based on provided parameters
  Future<void> _initializeNavigation() async {
    final provider = context.read<QuranProvider>();

    if (widget.initialPageNumber != null) {
      // Direct page navigation
      _jumpToPage(widget.initialPageNumber!);
    } else if (widget.initialAyahNumber != null) {
      // Navigate to specific ayah - calculate page for mashaf mode
      final page = await provider.getPageForAyah(
        widget.initialSurahNumber,
        widget.initialAyahNumber!,
      );
      if (mounted) {
        setState(() {
          _currentPage = page > 0 ? page : 1;
          _targetTranslationAyah = widget.initialAyahNumber;
        });
        if (_viewMode == ViewMode.mashaf) {
          _jumpToPage(_currentPage);
        }
      }
    } else {
      // Navigate to surah start
      final page = await provider.getSurahStartPage(_currentSurahNumber);
      if (mounted) {
        _jumpToPage(page);
      }
    }
  }

  void _jumpToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    } else {
      _pageController = PageController(initialPage: page - 1);
    }
  }

  void _loadCurrentSurah() {
    final provider = context.read<QuranProvider>();
    if (provider.surahs.isNotEmpty) {
      setState(() {
        _currentSurah = provider.surahs.firstWhere(
          (s) => s.number == _currentSurahNumber,
          orElse: () => provider.surahs.first,
        );
      });
    }
  }

  /// Show search/jump dialog to navigate to specific surah:ayah
  void _showJumpToAyahDialog() {
    final surahController = TextEditingController(
      text: _currentSurahNumber.toString(),
    );
    final ayahController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final backgroundColor = GlassTheme.background(isDark);

        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.search, color: accentColor),
              const SizedBox(width: 8),
              Text('Go to Verse', style: TextStyle(color: textColor)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: surahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Surah Number (1-114)',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.book, color: accentColor),
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ayahController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Verse Number',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.format_list_numbered,
                    color: accentColor,
                  ),
                ),
                style: TextStyle(color: textColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              onPressed: () => _handleJumpToAyah(
                dialogContext,
                surahController.text,
                ayahController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleJumpToAyah(
    BuildContext dialogContext,
    String surahText,
    String ayahText,
  ) async {
    final surahNum = int.tryParse(surahText);
    final ayahNum = int.tryParse(ayahText);

    if (surahNum == null || surahNum < 1 || surahNum > 114) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Surah (1-114)')),
      );
      return;
    }

    if (ayahNum == null || ayahNum < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Ayah number')),
      );
      return;
    }

    Navigator.pop(dialogContext);

    final provider = context.read<QuranProvider>();

    // Update current surah if changed
    if (surahNum != _currentSurahNumber) {
      _currentSurahNumber = surahNum;
      _loadCurrentSurah();
    }

    // Navigate based on current view mode
    if (_viewMode == ViewMode.mashaf) {
      final page = await provider.getPageForAyah(surahNum, ayahNum);
      if (mounted && page > 0) {
        _jumpToPage(page);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jumped to Surah $surahNum, Ayah $ayahNum (Page $page)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Translation mode - scroll to ayah
      setState(() {
        _targetTranslationAyah = ayahNum;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jumped to Surah $surahNum, Ayah $ayahNum'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _currentAyahNumber = ayahNum;
  }

  void _toggleViewMode() async {
    final provider = context.read<QuranProvider>();

    if (_viewMode == ViewMode.mashaf) {
      // Switching to Translation
      final surahNum = await provider.getSurahForPage(_currentPage);
      setState(() {
        _currentSurahNumber = surahNum;
        _loadCurrentSurah();
        _viewMode = ViewMode.translation;
      });
      provider.toggleMode();
    } else {
      // Switching to Mashaf
      int targetAyah = 1;

      // Try to get from visible items
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final sorted = positions.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        for (var pos in sorted) {
          if (pos.index > 0) {
            targetAyah = pos.index;
            break;
          }
        }
      } else if (_targetTranslationAyah != null) {
        targetAyah = _targetTranslationAyah!;
      }

      final page = await provider.getPageForAyah(
        _currentSurahNumber,
        targetAyah,
      );
      setState(() {
        _currentPage = page > 0 ? page : 1;
        _viewMode = ViewMode.mashaf;
        _jumpToPage(_currentPage);
      });
      provider.toggleMode();
    }
  }

  void _toggleImmersive() {
    setState(() {
      _isImmersive = !_isImmersive;
    });
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _onPageChanged(int page) async {
    final provider = context.read<QuranProvider>();
    final surahNum = await provider.getSurahForPage(page + 1);

    if (mounted) {
      setState(() {
        _currentPage = page + 1;
        if (surahNum != _currentSurahNumber) {
          _currentSurahNumber = surahNum;
          _loadCurrentSurah();
        }
      });
      _saveLastRead();
    }
  }

  void _saveLastRead() {
    final provider = context.read<QuranProvider>();
    provider.saveLastRead(
      surahNumber: _currentSurahNumber,
      ayahNumber: _currentAyahNumber ?? 1,
      pageNumber: _currentPage,
      surahName: _currentSurah?.englishName ?? 'Surah $_currentSurahNumber',
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final settingsProvider = Provider.of<SettingsProvider>(context);
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final backgroundColor = GlassTheme.background(isDark);
        final borderColor = GlassTheme.glassBorder(isDark);

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              if (_viewMode == ViewMode.translation) ...[
                Text(
                  'Translation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<QuranProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        _buildTranslationOption(
                          provider,
                          'ဦးဘစိန်',
                          'basein',
                          isDark,
                          textColor,
                        ),
                        _buildTranslationOption(
                          provider,
                          'ဃာဇီဟာရှင်မ်',
                          'ghazimohammadha',
                          isDark,
                          textColor,
                        ),
                        _buildTranslationOption(
                          provider,
                          'ဟာရှင်မ်တင်မြင့်',
                          'hashimtinmyint',
                          isDark,
                          textColor,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranslationOption(
    QuranProvider provider,
    String label,
    String key,
    bool isDark,
    Color textColor,
  ) {
    return RadioListTile<String>(
      title: Text(label, style: TextStyle(color: textColor)),
      value: key,
      groupValue: provider.selectedTranslationKey,
      onChanged: (value) {
        if (value != null) {
          provider.setTranslationKey(value);
          Navigator.pop(context);
        }
      },
      activeColor: GlassTheme.accent(isDark),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onAyahTapped(int surah, int ayah) {
    setState(() {
      _selectedAyah = {'surah': surah, 'ayah': ayah};
      _currentAyahNumber = ayah;
    });
    _showAyahMenu(surah, ayah);
  }

  void _showAyahMenu(int surah, int ayah) {
    final provider = context.read<QuranProvider>();
    final isBookmarked = provider.isBookmarked(surah, ayah);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final backgroundColor = GlassTheme.background(isDark);
        final borderColor = GlassTheme.glassBorder(isDark);

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Surah ${_currentSurah?.englishName ?? surah}, Ayah $ayah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _switchToTranslation(surah, ayah);
                },
                icon: const Icon(Icons.translate),
                label: const Text('View Translation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        provider.toggleBookmark(
                          surahNumber: surah,
                          ayahNumber: ayah,
                          surahName:
                              _currentSurah?.englishName ?? 'Surah $surah',
                          pageNumber: _currentPage,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBookmarked
                                  ? 'Bookmark removed'
                                  : 'Bookmark added',
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(isBookmarked ? 'Remove' : 'Bookmark'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final ayahData = await provider.getAyah(surah, ayah);
                        if (ayahData != null) {
                          final translation =
                              ayahData.translations?[provider
                                  .selectedTranslationKey] ??
                              '';
                          final textToCopy =
                              '${ayahData.text}\n\n$translation\n\n[${_currentSurah?.englishName ?? 'Surah $surah'} $surah:$ayah]';
                          await Clipboard.setData(
                            ClipboardData(text: textToCopy),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _selectedAyah = null;
      });
    });
  }

  void _switchToTranslation(int surah, int ayah) async {
    final provider = context.read<QuranProvider>();

    if (_currentSurahNumber != surah) {
      _currentSurahNumber = surah;
      _loadCurrentSurah();
    }

    setState(() {
      _targetTranslationAyah = ayah;
      _viewMode = ViewMode.translation;
    });

    if (provider.isMashafMode) {
      provider.toggleMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final backgroundColor = GlassTheme.background(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: Stack(
              children: [
                // Main Content
                GestureDetector(
                  onTap: _toggleImmersive,
                  child: _viewMode == ViewMode.mashaf
                      ? MashafView(
                          pageController: _pageController,
                          onPageChanged: _onPageChanged,
                          onAyahTap: _onAyahTapped,
                          selectedAyah: _selectedAyah,
                        )
                      : _currentSurah != null
                      ? TranslationView(
                          surah: _currentSurah!,
                          initialAyah:
                              _targetTranslationAyah ??
                              widget.initialAyahNumber,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          onNextSurah: () {
                            if (_currentSurahNumber < 114) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _currentSurahNumber++;
                                _targetTranslationAyah =
                                    null; // Start at top (Header)
                              });
                              _loadCurrentSurah();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This is the last Surah'),
                                ),
                              );
                            }
                          },
                          onPreviousSurah: () {
                            if (_currentSurahNumber > 1) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _currentSurahNumber--;
                                _targetTranslationAyah =
                                    null; // Start at top (Header)
                              });
                              _loadCurrentSurah();
                            }
                          },
                        )
                      : Center(
                          child: CircularProgressIndicator(color: accentColor),
                        ),
                ),

                // Top Bar Overlay
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _isImmersive ? -100 : 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 12,
                      left: 8,
                      right: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentSurah?.englishName ??
                                    'Surah $_currentSurahNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _viewMode == ViewMode.mashaf
                                    ? 'Page $_currentPage'
                                    : 'Translation',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Search/Jump button
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          tooltip: 'Jump to Ayah',
                          onPressed: _showJumpToAyahDialog,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                          tooltip: 'Surah Info',
                          onPressed: () {
                            if (_currentSurah != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SurahInfoScreen(surah: _currentSurah!),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _viewMode == ViewMode.mashaf
                                ? Icons.translate
                                : Icons.auto_stories,
                            color: Colors.white,
                          ),
                          onPressed: _toggleViewMode,
                          tooltip: _viewMode == ViewMode.mashaf
                              ? 'Translation View'
                              : 'Mashaf View',
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: _showSettingsDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
