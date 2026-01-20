import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/hadith_provider.dart';
import '../providers/settings_provider.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class HadithSectionScreen extends StatefulWidget {
  final int chapterId;
  final String chapterName;
  final dynamic scrollToHadith;

  const HadithSectionScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
    this.scrollToHadith,
  });

  @override
  State<HadithSectionScreen> createState() => _HadithSectionScreenState();
}

class _HadithSectionScreenState extends State<HadithSectionScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToHadith != null) {
        _scrollToHadith(widget.scrollToHadith!);
      }
      final provider = context.read<HadithProvider>();
      if (provider.selectedLanguage == 'my') {
        _checkAndShowWarning();
      }
    });
  }

  Future<void> _checkAndShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('hadith_ai_warning_seen') ?? false;
    if (!hasSeenWarning && mounted) {
      _showAiTranslationWarning();
    }
  }

  void _showAiTranslationWarning() {
    final isDark = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final textColor = GlassTheme.text(isDark);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.background(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('သတိပေးချက်', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
          'ယခု app ရှိ ဟဒီစ်တော်များသည် english ဟဒီစ်ဘာသာပြန်များမှ AI ဖြင့် ဘာသာပြန်ဆိုထားသော အချက်အလက်များဖြစ်ပါသည်။',
          style: TextStyle(
            fontFamily: 'Myanmar',
            fontSize: 16,
            height: 1.6,
            color: textColor,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.accent(isDark),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hadith_ai_warning_seen', true);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'နားလည်ပြီ ထပ်သတိမပေးနဲ့တော့',
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

  void _scrollToHadith(dynamic hadithNumber) {
    if (_hasScrolled) return;
    final provider = context.read<HadithProvider>();
    final index = provider.currentHadiths.indexWhere(
      (h) => h.idInBook.toString() == hadithNumber.toString(),
    );
    if (index != -1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: index,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutCubic,
          );
          _hasScrolled = true;
        }
      });
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
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(isDark, textColor),
                _buildChapterHeader(isDark, textColor),
                Expanded(child: _buildContent(isDark, textColor, accentColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          Consumer<HadithProvider>(
            builder: (context, provider, _) => PopupMenuButton<String>(
              initialValue: provider.selectedLanguage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.language, color: textColor),
              ),
              onSelected: (lang) {
                provider.changeLanguage(lang);
                if (lang == 'my') {
                  _checkAndShowWarning();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'ara', child: Text('Arabic')),
                const PopupMenuItem(value: 'eng', child: Text('English')),
                const PopupMenuItem(value: 'my', child: Text('Burmese')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterHeader(bool isDark, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 20,
        child: Text(
          widget.chapterName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor, Color accentColor) {
    return Consumer<HadithProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (provider.currentHadiths.isEmpty) {
          return Center(
            child: Text(
              'No hadiths found',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          );
        }
        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          padding: const EdgeInsets.all(16),
          itemCount: provider.currentHadiths.length,
          itemBuilder: (context, index) {
            final hadith = provider.currentHadiths[index];
            return _buildHadithCard(
              hadith,
              provider.selectedLanguage,
              provider.selectedBookKey,
              isDark,
              textColor,
              accentColor,
            );
          },
        );
      },
    );
  }

  Widget _buildHadithCard(
    Hadith hadith,
    String language,
    String bookKey,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildHadithHeader(hadith, bookKey, isDark, textColor, accentColor),
            Divider(height: 1, color: textColor.withValues(alpha: 0.1)),
            _buildHadithContent(hadith, language, isDark, textColor),
            Divider(height: 1, color: textColor.withValues(alpha: 0.1)),
            _buildHadithActions(
              hadith,
              bookKey,
              language,
              isDark,
              textColor,
              accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithHeader(
    Hadith hadith,
    String bookKey,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final bookName = HadithService.bookNames[bookKey] ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Hadith ${hadith.idInBook}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bookName,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hadith.references != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hadith.references!.reference.isNotEmpty)
                  _buildReferenceChip(
                    hadith.references!.reference,
                    Icons.menu_book_rounded,
                    isDark,
                    textColor,
                  ),
                if (hadith.references!.inBookReference.isNotEmpty)
                  _buildReferenceChip(
                    hadith.references!.inBookReference,
                    Icons.library_books_rounded,
                    isDark,
                    textColor,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceChip(
    String label,
    IconData icon,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label.replaceAll(':', '').trim(),
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithContent(
    Hadith hadith,
    String language,
    bool isDark,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hadith.chapterInfo != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: textColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    hadith.chapterInfo!.arabic,
                    style: TextStyle(
                      fontFamily: 'Indopak',
                      fontSize: 22,
                      letterSpacing: 0,
                      color: textColor,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  if (language != 'ara') ...[
                    const SizedBox(height: 12),
                    Text(
                      '${hadith.chapterInfo!.english} ${hadith.chapterInfo!.number}',
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
          Text(
            hadith.arabic,
            style: TextStyle(
              fontFamily: 'Indopak',
              fontSize: 28,
              height: 2.4,
              letterSpacing: 0,
              color: textColor,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (language != 'ara') ...[
            const SizedBox(height: 24),
            Divider(color: textColor.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            if (language == 'eng' && hadith.english['narrator'] != null)
              Text(
                hadith.english['narrator']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            if (language == 'my' && hadith.burmese['narrator'] != null)
              Text(
                hadith.burmese['narrator']!,
                style: TextStyle(
                  fontFamily: 'Myanmar',
                  fontSize: 18,
                  height: 2.0,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            const SizedBox(height: 12),
            if (language == 'eng')
              Text(
                hadith.english['text'] ?? '',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            if (language == 'my')
              Text(
                hadith.burmese['text'] ?? '',
                style: TextStyle(
                  fontFamily: 'Myanmar',
                  fontSize: 18,
                  height: 2.2,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHadithActions(
    Hadith hadith,
    String bookKey,
    String language,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            isDark: isDark,
            textColor: textColor,
            onTap: () {
              String translationText = '';
              if (language == 'eng') {
                final narrator = hadith.english['narrator'] ?? '';
                final text = hadith.english['text'] ?? '';
                translationText = narrator.isNotEmpty
                    ? '$narrator\n\n$text'
                    : text;
              } else if (language == 'my') {
                final narrator = hadith.burmese['narrator'] ?? '';
                final text = hadith.burmese['text'] ?? '';
                translationText = narrator.isNotEmpty
                    ? '$narrator\n\n$text'
                    : text;
              }
              final fullText = language == 'ara'
                  ? hadith.arabic
                  : '${hadith.arabic}\n\n$translationText';
              Clipboard.setData(ClipboardData(text: fullText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isDark: isDark,
            textColor: textColor,
            onTap: () {
              final bookName = HadithService.bookNames[bookKey] ?? '';
              String translationText = '';
              if (language == 'eng') {
                final narrator = hadith.english['narrator'] ?? '';
                final text = hadith.english['text'] ?? '';
                translationText = narrator.isNotEmpty
                    ? '$narrator\n\n$text'
                    : text;
              } else if (language == 'my') {
                final narrator = hadith.burmese['narrator'] ?? '';
                final text = hadith.burmese['text'] ?? '';
                translationText = narrator.isNotEmpty
                    ? '$narrator\n\n$text'
                    : text;
              }
              final shareText = language == 'ara'
                  ? '${hadith.arabic}\n\n$bookName - Hadith ${hadith.idInBook}'
                  : '${hadith.arabic}\n\n$translationText\n\n$bookName - Hadith ${hadith.idInBook}';
              // ignore: deprecated_member_use
              Share.share(shareText, subject: 'Hadith ${hadith.idInBook}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: textColor.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
