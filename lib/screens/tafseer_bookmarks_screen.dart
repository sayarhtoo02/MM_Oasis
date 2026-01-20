import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tafseer_preferences_service.dart';
import '../services/tafseer_service.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import 'tafseer_screen.dart';

class TafseerBookmarksScreen extends StatefulWidget {
  const TafseerBookmarksScreen({super.key});

  @override
  State<TafseerBookmarksScreen> createState() => _TafseerBookmarksScreenState();
}

class _TafseerBookmarksScreenState extends State<TafseerBookmarksScreen>
    with TickerProviderStateMixin {
  List<String> bookmarks = [];
  Map<String, TafseerItem?> tafseerCache = {};
  bool isLoading = true;
  String currentLanguage = 'my';

  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadBookmarks();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() => isLoading = true);

    bookmarks = await TafseerPreferencesService.getBookmarks();
    currentLanguage = await TafseerPreferencesService.getLanguage();

    for (String ayahKey in bookmarks) {
      try {
        List<TafseerItem> items;
        if (currentLanguage == 'my') {
          items = await TafseerService.getMyanmarTafseer(ayahKey);
        } else {
          items = await TafseerService.getEnglishTafseer(ayahKey);
        }
        tafseerCache[ayahKey] = items.isNotEmpty ? items.first : null;
      } catch (e) {
        tafseerCache[ayahKey] = null;
      }
    }

    setState(() => isLoading = false);
    _listAnimationController.forward();
  }

  Future<void> _removeBookmark(String ayahKey) async {
    await TafseerPreferencesService.removeBookmark(ayahKey);
    setState(() {
      bookmarks.remove(ayahKey);
      tafseerCache.remove(ayahKey);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentLanguage == 'my' ? 'စာမှတ်ဖယ်ရှားပြီး' : 'Bookmark removed',
        ),
        action: SnackBarAction(
          label: currentLanguage == 'my' ? 'ပြန်ထည့်' : 'Undo',
          onPressed: () async {
            await TafseerPreferencesService.addBookmark(ayahKey);
            _loadBookmarks();
          },
        ),
      ),
    );
  }

  void _navigateToTafseer(String ayahKey) {
    final parts = ayahKey.split(':');
    if (parts.length == 2) {
      final surahNumber = int.tryParse(parts[0]);
      final ayahNumber = int.tryParse(parts[1]);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TafseerScreen(
            ayahKey: ayahKey,
            surahName: 'Surah $surahNumber',
            ayahNumber: ayahNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: currentLanguage == 'my'
              ? 'တဖ်စီရ် စာမှတ်များ'
              : 'Tafseer Bookmarks',
          actions: [
            if (bookmarks.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textColor),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog(isDark, textColor, accentColor);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.clear_all, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          currentLanguage == 'my'
                              ? 'အားလုံးဖယ်ရှား'
                              : 'Clear All',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          body: _buildBody(isDark, textColor, accentColor),
        );
      },
    );
  }

  Widget _buildBody(bool isDark, Color textColor, Color accentColor) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            const SizedBox(height: 16),
            Text(
              currentLanguage == 'my'
                  ? 'စာမှတ်များ ရှာနေသည်...'
                  : 'Loading bookmarks...',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              currentLanguage == 'my'
                  ? 'စာမှတ်များ မရှိပါ'
                  : 'No bookmarks yet',
              style: TextStyle(
                fontSize: 20,
                color: textColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                currentLanguage == 'my'
                    ? 'တဖ်စီရ်များကို ဖတ်ရှုပြီး စာမှတ်ထားနိုင်ပါသည်'
                    : 'Start reading tafseer and bookmark your favorites',
                style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.book, color: Colors.white),
              label: Text(
                currentLanguage == 'my' ? 'တဖ်စီရ် ဖတ်ရှုရန်' : 'Read Tafseer',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _listAnimationController,
                curve: Interval(
                  index * 0.1,
                  (index * 0.1) + 0.3,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildBookmarkItem(
                  bookmarks[index],
                  index,
                  isDark,
                  GlassTheme.text(isDark),
                  GlassTheme.accent(isDark),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookmarkItem(
    String ayahKey,
    int index,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final tafseerItem = tafseerCache[ayahKey];
    final parts = ayahKey.split(':');
    final surahNumber = parts.isNotEmpty ? parts[0] : '';
    final ayahNumber = parts.length > 1 ? parts[1] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        onTap: () => _navigateToTafseer(ayahKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentLanguage == 'my'
                        ? 'ဆူရာ $surahNumber - အာယတ် $ayahNumber'
                        : 'Surah $surahNumber - Ayah $ayahNumber',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeBookmark(ayahKey),
                  icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                  tooltip: currentLanguage == 'my'
                      ? 'စာမှတ်ဖယ်ရှား'
                      : 'Remove bookmark',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tafseerItem != null) ...[
              Text(
                _getPreviewText(tafseerItem.text),
                style: TextStyle(
                  height: 1.6,
                  fontFamily: currentLanguage == 'my' ? 'Myanmar' : null,
                  color: textColor.withValues(alpha: 0.9),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentLanguage == 'my' ? 'စာမှတ်ထားပြီး' : 'Bookmarked',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentLanguage == 'my'
                          ? 'တဖ်စီရ် ရှာမတွေ့ပါ'
                          : 'Tafseer not found',
                      style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String htmlText) {
    String cleanText = htmlText
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanText.length > 150) {
      return '${cleanText.substring(0, 150)}...';
    }
    return cleanText;
  }

  void _showClearAllDialog(bool isDark, Color textColor, Color accentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.background(isDark),
        title: Text(
          currentLanguage == 'my' ? 'အားလုံးဖယ်ရှားမည်' : 'Clear All Bookmarks',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          currentLanguage == 'my'
              ? 'စာမှတ်အားလုံးကို ဖယ်ရှားလိုပါသလား?'
              : 'Are you sure you want to remove all bookmarks?',
          style: TextStyle(color: textColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'my' ? 'မလုပ်တော့' : 'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (String ayahKey in List.from(bookmarks)) {
                await TafseerPreferencesService.removeBookmark(ayahKey);
              }
              setState(() {
                bookmarks.clear();
                tafseerCache.clear();
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentLanguage == 'my'
                        ? 'စာမှတ်အားလုံး ဖယ်ရှားပြီး'
                        : 'All bookmarks cleared',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(currentLanguage == 'my' ? 'ဖယ်ရှား' : 'Clear'),
          ),
        ],
      ),
    );
  }
}
