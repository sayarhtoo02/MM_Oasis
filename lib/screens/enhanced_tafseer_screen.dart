import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/tafseer_widget.dart';
import '../services/tafseer_service.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';

class EnhancedTafseerScreen extends StatefulWidget {
  final String ayahKey;
  final String? surahName;
  final int? ayahNumber;

  const EnhancedTafseerScreen({
    super.key,
    required this.ayahKey,
    this.surahName,
    this.ayahNumber,
  });

  @override
  State<EnhancedTafseerScreen> createState() => _EnhancedTafseerScreenState();
}

class _EnhancedTafseerScreenState extends State<EnhancedTafseerScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late AnimationController _appBarAnimationController;

  bool _showScrollToTop = false;
  bool _isFullscreen = false;
  bool _isBookmarked = false;

  final String _currentLanguage = 'my';

  // Reading preferences
  double _fontSize = 16.0;
  double _lineHeight = 1.8;
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadBookmarkStatus();
    _checkAndShowWarning();
  }

  Future<void> _checkAndShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tafseer_ai_warning_seen', false);
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
          'ဤတဖ်စီရ်အချက်အလက်များသည် တဖ်စီရ် အစ်ဗ်န် ကသီရ် (အင်္ဂလိပ်ဘာသာပြန်) မှ AI ဖြင့် ဘာသာပြန်ဆိုထားသော အချက်အလက်များဖြစ်သည်။ ဘာသာပြန်ဆိုမှုတွင် အမှားအယွင်းများ အဆီအငေါ်မတည့်မှူများ ရှိနိုင်ပါသည်။ အရေးကြီးသော ဘာသာရေးဆိုင်ရာ ဆုံးဖြတ်ချက်များအတွက် မူရင်းအင်္ဂလိပ်ဘာသာ သို့မဟုတ် အာရဗီဘာသာကိုသာ အသုံးပြုပါ။ ',
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
    _fabAnimationController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
      _fabAnimationController.forward();
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
      _fabAnimationController.reverse();
    }
  }

  void _loadBookmarkStatus() {
    // TODO: Load from shared preferences or database
    setState(() => _isBookmarked = false);
  }

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    // TODO: Save to shared preferences or database

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

  void _shareContent() async {
    try {
      final items = await TafseerService.getMyanmarTafseer(widget.ayahKey);
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

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _appBarAnimationController.reverse();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _appBarAnimationController.forward();
    }
  }

  void _showReadingOptionsBottomSheet() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReadingOptionsSheet(isDark, textColor),
    );
  }

  Widget _buildReadingOptionsSheet(bool isDark, Color textColor) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: GlassTheme.glassGradient(isDark)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: GlassTheme.glassBorder(isDark)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentLanguage == 'my'
                  ? 'ဖတ်ရှုခြင်းဆိုင်ရာ'
                  : 'Reading Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildOptionTile(
                  title: _currentLanguage == 'my'
                      ? 'စာလုံးအရွယ်အစား'
                      : 'Font Size',
                  isDark: isDark,
                  textColor: textColor,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () => _fontSize = (_fontSize - 1).clamp(12, 24),
                        ),
                        icon: Icon(Icons.remove, color: textColor),
                      ),
                      Text(
                        '${_fontSize.toInt()}',
                        style: TextStyle(color: textColor),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _fontSize = (_fontSize + 1).clamp(12, 24),
                        ),
                        icon: Icon(Icons.add, color: textColor),
                      ),
                    ],
                  ),
                ),
                _buildOptionTile(
                  title: _currentLanguage == 'my'
                      ? 'စာကြောင်းအကွာအဝေး'
                      : 'Line Spacing',
                  isDark: isDark,
                  textColor: textColor,
                  child: Slider(
                    value: _lineHeight,
                    min: 1.2,
                    max: 2.5,
                    divisions: 13,
                    label: _lineHeight.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _lineHeight = value),
                  ),
                ),
                _buildOptionTile(
                  title: _currentLanguage == 'my'
                      ? 'နောက်ခံအရောင်'
                      : 'Background',
                  isDark: isDark,
                  textColor: textColor,
                  child: Row(
                    children: [
                      _buildColorOption(Colors.white, 'Light'),
                      _buildColorOption(const Color(0xFFF5F5DC), 'Sepia'),
                      _buildColorOption(const Color(0xFF1E1E1E), 'Dark'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required Widget child,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.glassGradient(isDark)[0],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTheme.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, String label) {
    final isSelected = _backgroundColor == color;
    return GestureDetector(
      onTap: () => setState(() {
        _backgroundColor = color;
        _textColor = color == const Color(0xFF1E1E1E)
            ? Colors.white
            : Colors.black87;
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GlassTheme.accent(false) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color == const Color(0xFF1E1E1E)
                    ? Colors.white
                    : Colors.black87,
              ),
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
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (_isFullscreen) {
          return Scaffold(
            backgroundColor: _backgroundColor,
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
                            icon: Icon(Icons.arrow_back, color: _textColor),
                          ),
                          Expanded(
                            child: Text(
                              widget.surahName != null &&
                                      widget.ayahNumber != null
                                  ? '${widget.surahName} - Ayah ${widget.ayahNumber}'
                                  : 'Tafseer Ibn Kathir',
                              style: TextStyle(
                                fontSize: 18,
                                color: _textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _showReadingOptionsBottomSheet,
                            icon: Icon(Icons.tune, color: _textColor),
                          ),
                          IconButton(
                            onPressed: _toggleFullscreen,
                            icon: Icon(
                              Icons.fullscreen_exit,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TafseerWidget(
                      ayahKey: widget.ayahKey,
                      language: _currentLanguage,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            floatingActionButton: AnimatedBuilder(
              animation: _fabAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabAnimationController.value,
                  child: FloatingActionButton.small(
                    onPressed: () => _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                );
              },
            ),
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
            ),
            IconButton(
              onPressed: _shareContent,
              icon: Icon(Icons.share, color: textColor),
            ),
            IconButton(
              onPressed: _showReadingOptionsBottomSheet,
              icon: Icon(Icons.tune, color: textColor),
            ),
            IconButton(
              onPressed: _toggleFullscreen,
              icon: Icon(Icons.fullscreen, color: textColor),
            ),
          ],
          floatingActionButton: AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimationController.value,
                child: FloatingActionButton.small(
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              );
            },
          ),
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
                TafseerWidget(
                  ayahKey: widget.ayahKey,
                  language: _currentLanguage,
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
