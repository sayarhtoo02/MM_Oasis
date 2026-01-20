import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sunnah_collection_model.dart';
import '../../services/sunnah_service.dart';
import 'sunnah_detail_screen.dart';
import 'book_info_screen.dart';
import '../../config/glass_theme.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_card.dart';
import '../../providers/settings_provider.dart';

class SunnahChaptersScreen extends StatefulWidget {
  const SunnahChaptersScreen({super.key});

  @override
  State<SunnahChaptersScreen> createState() => _SunnahChaptersScreenState();
}

class _SunnahChaptersScreenState extends State<SunnahChaptersScreen>
    with SingleTickerProviderStateMixin {
  final SunnahService _service = SunnahService();
  late Future<List<SunnahChapter>> _chaptersFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = _service.getAllChapters();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Sunnah Collection',
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline_rounded, color: accentColor),
              onPressed: _navigateToBookInfo,
              tooltip: 'Book Info',
            ),
          ],
          body: Column(
            children: [
              _buildHeader(isDark, textColor, accentColor),
              Expanded(child: _buildContent(isDark, textColor, accentColor)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToBookInfo() async {
    final bookInfo = await SunnahService().getBookInfo();
    if (bookInfo != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookInfoScreen(bookInfo: bookInfo),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load book information')),
      );
    }
  }

  Widget _buildHeader(bool isDark, Color textColor, Color accentColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = 0.1;
        final rawValue = ((_animationController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        final animValue = Curves.easeOutCubic.transform(rawValue);
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow the Sunnah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of the Prophet (SAW)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor, Color accentColor) {
    return FutureBuilder<List<SunnahChapter>>(
      future: _chaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: accentColor, strokeWidth: 3),
                const SizedBox(height: 16),
                Text(
                  'Loading chapters...',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: textColor.withValues(alpha: 0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading chapters',
                  style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  color: textColor.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No chapters found',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final chapters = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${chapters.length} Chapters',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return _buildChapterCard(
                    chapter,
                    chapters,
                    index,
                    isDark,
                    textColor,
                    accentColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChapterCard(
    SunnahChapter chapter,
    List<SunnahChapter> chapters,
    int index,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = 0.2 + (index * 0.05).clamp(0.0, 0.5);
        final rawValue = ((_animationController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        final animValue = Curves.easeOutCubic.transform(rawValue);
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 20,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SunnahDetailScreen(
                      chapter: chapter,
                      allChapters: chapters,
                      currentIndex: index,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.chapterId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.chapterTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.4,
                          fontFamily: 'Myanmar',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_list_numbered_rounded,
                              size: 12,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${chapter.items.length} items',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
