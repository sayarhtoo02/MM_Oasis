import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_tafseer_widget.dart';
import '../services/tafseer_preferences_service.dart';
import '../services/tafseer_service.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import 'tafseer_bookmarks_screen.dart';

class TafseerScreen extends StatefulWidget {
  final String ayahKey;
  final String? surahName;
  final int? ayahNumber;

  const TafseerScreen({
    super.key,
    required this.ayahKey,
    this.surahName,
    this.ayahNumber,
  });

  @override
  State<TafseerScreen> createState() => _TafseerScreenState();
}

class _TafseerScreenState extends State<TafseerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _isFullscreen = false;
  bool _isBookmarked = false;
  String _currentLanguage = 'my';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadBookmarkStatus();
    _loadLanguage();
    _checkAndShowWarning();
  }

  Future<void> _checkAndShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('tafseer_ai_warning_seen') ?? false;

    if (!hasSeenWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAiTranslationWarning();
        }
      });
    }
  }

  void _showAiTranslationWarning() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.background(isDark),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('သတိပေးချက်', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
          'ဤတဖ်စီရ်အချက်အလက်များသည် တဖ်စီရ် အစ်ဗ်န် ကသီရ် (အင်္ဂလိပ်ဘာသာပြန်) မှ AI ဖြင့် ဘာသာပြန်ဆိုထားသော အချက်အလက်များဖြစ်သည်။ ဘာသာပြန်ဆိုမှုတွင် အမှားအယွင်းများ ရှိနိုင်ပါသည်။ အရေးကြီးသော ဘာသာရေးဆိုင်ရာ ဆုံးဖြတ်ချက်များအတွက် မူရင်းအင်္ဂလိပ်ဘာသာ သို့မဟုတ် အာရဗီဘာသာကိုသာ အသုံးပြုပါ။',
          style: TextStyle(
            fontFamily: 'Myanmar',
            fontSize: 16,
            height: 1.6,
            color: textColor.withValues(alpha: 0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'နားလည်ပြီ',
              style: TextStyle(
                fontFamily: 'Myanmar',
                fontSize: 16,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('tafseer_ai_warning_seen', true);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text(
              'နားလည်ပြီ ထပ်သတိမပေးနဲ့တော့ ',
              style: TextStyle(
                fontFamily: 'Myanmar',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _loadBookmarkStatus() async {
    final isBookmarked = await TafseerPreferencesService.isBookmarked(
      widget.ayahKey,
    );
    setState(() => _isBookmarked = isBookmarked);
  }

  Future<void> _loadLanguage() async {
    final language = await TafseerPreferencesService.getLanguage();
    setState(() => _currentLanguage = language);
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await TafseerPreferencesService.removeBookmark(widget.ayahKey);
    } else {
      await TafseerPreferencesService.addBookmark(widget.ayahKey);
    }

    setState(() => _isBookmarked = !_isBookmarked);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked
              ? (_currentLanguage == 'my' ? 'စာမှတ်ထားပြီး' : 'Bookmarked')
              : (_currentLanguage == 'my'
                    ? 'စာမှတ်ဖယ်ရှားပြီး'
                    : 'Bookmark removed'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareContent() async {
    try {
      final items = _currentLanguage == 'my'
          ? await TafseerService.getMyanmarTafseer(widget.ayahKey)
          : await TafseerService.getEnglishTafseer(widget.ayahKey);

      if (items.isNotEmpty) {
        final content = items.first.text
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final shareText =
            '''
Tafseer Ibn Kathir
${widget.surahName} - Ayah ${widget.ayahNumber}

$content

Shared from Munajat-e-Maqbool App
        ''';

        await SharePlus.instance.share(ShareParams(text: shareText));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLanguage == 'my' ? 'မျှဝေ၍မရပါ' : 'Unable to share',
            ),
          ),
        );
      }
    }
  }

  void _navigateToBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TafseerBookmarksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (_isFullscreen) {
          return Scaffold(
            backgroundColor: GlassTheme.background(isDark),
            body: SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: textColor),
                          ),
                          IconButton(
                            onPressed: _toggleBookmark,
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isBookmarked ? Colors.amber : textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: _shareContent,
                            icon: Icon(Icons.share, color: textColor),
                          ),
                          Expanded(
                            child: Text(
                              widget.surahName != null &&
                                      widget.ayahNumber != null
                                  ? '${widget.surahName} - Ayah ${widget.ayahNumber}'
                                  : 'Tafseer Ibn Kathir',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _navigateToBookmarks,
                            icon: Icon(Icons.bookmarks, color: textColor),
                          ),
                          IconButton(
                            onPressed: _toggleFullscreen,
                            icon: Icon(Icons.fullscreen_exit, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    EnhancedTafseerWidget(
                      ayahKey: widget.ayahKey,
                      initialLanguage: _currentLanguage,
                      onLanguageChanged: (language) =>
                          setState(() => _currentLanguage = language),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            floatingActionButton: _showScrollToTop
                ? FloatingActionButton.small(
                    onPressed: _scrollToTop,
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.keyboard_arrow_up),
                  )
                : null,
          );
        }

        return GlassScaffold(
          title: 'Tafseer Ibn Kathir',
          actions: [
            IconButton(
              onPressed: _toggleBookmark,
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? Colors.amber : textColor,
              ),
              tooltip: _isBookmarked
                  ? (_currentLanguage == 'my'
                        ? 'စာမှတ်ဖယ်ရှား'
                        : 'Remove bookmark')
                  : (_currentLanguage == 'my' ? 'စာမှတ်ထား' : 'Bookmark'),
            ),
            IconButton(
              onPressed: _shareContent,
              icon: Icon(Icons.share, color: textColor),
              tooltip: _currentLanguage == 'my' ? 'မျှဝေရန်' : 'Share',
            ),
            IconButton(
              onPressed: _navigateToBookmarks,
              icon: Icon(Icons.bookmarks, color: textColor),
              tooltip: _currentLanguage == 'my' ? 'စာမှတ်များ' : 'Bookmarks',
            ),
            IconButton(
              onPressed: _toggleFullscreen,
              icon: Icon(Icons.fullscreen, color: textColor),
              tooltip: 'Fullscreen',
            ),
          ],
          floatingActionButton: _showScrollToTop
              ? FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_up),
                )
              : null,
          body: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                if (widget.surahName != null && widget.ayahNumber != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${widget.surahName} - Ayah ${widget.ayahNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                EnhancedTafseerWidget(
                  ayahKey: widget.ayahKey,
                  initialLanguage: _currentLanguage,
                  onLanguageChanged: (language) =>
                      setState(() => _currentLanguage = language),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }
}
