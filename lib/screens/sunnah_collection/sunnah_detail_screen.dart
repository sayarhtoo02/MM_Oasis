import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/glass_theme.dart';
import '../../models/sunnah_collection_model.dart';
import '../../providers/settings_provider.dart';
import '../../screens/main_app_shell.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';

class SunnahDetailScreen extends StatefulWidget {
  final SunnahChapter chapter;
  final List<SunnahChapter> allChapters;
  final int currentIndex;

  const SunnahDetailScreen({
    super.key,
    required this.chapter,
    required this.allChapters,
    required this.currentIndex,
  });

  @override
  State<SunnahDetailScreen> createState() => _SunnahDetailScreenState();
}

class _SunnahDetailScreenState extends State<SunnahDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  bool _showTitle = false;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.currentIndex;
    _pageController = PageController(initialPage: widget.currentIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 100 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
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
          extendBody: true,
          bottomNavigationBar: _buildBottomNavBar(
            isDark,
            textColor,
            accentColor,
          ),
          body: Column(
            children: [
              _buildAppBar(context, isDark, textColor, accentColor),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allChapters.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                      _showTitle = false;
                    });
                    // Reset animation for new chapter
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemBuilder: (context, index) {
                    return _buildContent(
                      widget.allChapters[index],
                      isDark,
                      textColor,
                      accentColor,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _showTitle
            ? GlassTheme.glassGradient(isDark).first.withValues(alpha: 0.8)
            : null,
        border: _showTitle
            ? Border(bottom: BorderSide(color: GlassTheme.glassBorder(isDark)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: accentColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.allChapters[_currentPageIndex].chapterTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'Myanmar',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    SunnahChapter chapter,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: chapter.items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildChapterHeader(chapter, isDark, textColor, accentColor);
        }
        final item = chapter.items[index - 1];
        return _buildItemCard(
          item,
          context,
          index - 1,
          isDark,
          textColor,
          accentColor,
        );
      },
    );
  }

  Widget _buildChapterHeader(
    SunnahChapter chapter,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = Curves.easeOutCubic.transform(
          _animationController.value,
        );
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.chapterTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            fontFamily: 'Myanmar',
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.format_list_numbered_rounded,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${chapter.items.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    SunnahItem item,
    BuildContext context,
    int index,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = 0.1 + (index * 0.03).clamp(0.0, 0.3);
        final rawValue = ((_animationController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        final animValue = Curves.easeOutCubic.transform(rawValue);
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with ID and Share
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(color: GlassTheme.glassBorder(isDark)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_rounded,
                            color: accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'No. ${item.id}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shareItem(item, context),
                      icon: Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Burmese Text
                    SelectableText(
                      item.text,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Myanmar',
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    // Arabic Text
                    if (item.arabicText != null &&
                        item.arabicText!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.language_rounded,
                                        size: 12,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Arabic',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              item.arabicText!,
                              style: TextStyle(
                                fontFamily: 'Indopak',
                                letterSpacing: 0,
                                fontSize: 24,
                                height: 2.0,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Translation
                    if (item.urduTranslation != null &&
                        item.urduTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: SelectableText(
                          item.urduTranslation!,
                          style: TextStyle(
                            fontFamily: 'Myanmar',
                            fontSize: 16,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.8),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],

                    // Notes (Faidah)
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ...item.notes.map((note) {
                        final isFaidah = note.type == 'faidah';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFF8E1,
                            ).withValues(alpha: isDark ? 0.1 : 0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFFFFEEC0,
                              ).withValues(alpha: isDark ? 0.3 : 1.0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF856404,
                                      ).withValues(alpha: isDark ? 0.3 : 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 18,
                                      color: isDark
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFF856404),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isFaidah ? "Faidah (Note)" : "Note",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFF856404),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                note.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark
                                      ? const Color(0xFFFFD54F)
                                      : const Color(0xFF856404),
                                  fontFamily: 'Myanmar',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // References
                    if (item.references.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.collections_bookmark_rounded,
                                    size: 16,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'References',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor.withValues(alpha: 0.6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...item.references.map(
                              (ref) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: textColor.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SelectableText(
                                        ref,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareItem(SunnahItem item, BuildContext context) {
    String content = "${widget.chapter.chapterTitle}\n\n";
    content += "${item.text}\n";
    if (item.arabicText != null) content += "\n${item.arabicText}";
    if (item.urduTranslation != null) content += "\n${item.urduTranslation}";
    content += "\n\nShared from Munajat-e-Maqbool App";

    Share.share(content);
  }

  Widget _buildBottomNavBar(bool isDark, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainAppShellKey.currentState?.switchToTab(0);
                },
                textColor: textColor,
                accentColor: accentColor,
              ),
              _buildNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Quran',
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainAppShellKey.currentState?.switchToTab(2);
                },
                textColor: textColor,
                accentColor: accentColor,
              ),
              _buildNavItem(
                icon: Icons.library_books_rounded,
                label: 'Hadith',
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainAppShellKey.currentState?.switchToTab(3);
                },
                textColor: textColor,
                accentColor: accentColor,
              ),
              _buildNavItem(
                icon: Icons.auto_stories_rounded,
                label: 'Munajat',
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainAppShellKey.currentState?.switchToTab(1);
                },
                textColor: textColor,
                accentColor: accentColor,
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainAppShellKey.currentState?.switchToTab(6);
                },
                textColor: textColor,
                accentColor: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.7), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
