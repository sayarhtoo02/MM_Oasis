import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quran_surah.dart';
import '../../models/quran_ayah.dart';
import '../../providers/quran_provider.dart';
import '../../config/glass_theme.dart';
import '../../widgets/glass/glass_card.dart';
import '../../providers/settings_provider.dart';
import 'enhanced_tafseer_screen.dart';

class TranslationView extends StatefulWidget {
  final QuranSurah surah;
  final int? initialAyah;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  final VoidCallback? onNextSurah;
  final VoidCallback? onPreviousSurah;

  const TranslationView({
    super.key,
    required this.surah,
    this.initialAyah,
    required this.itemScrollController,
    required this.itemPositionsListener,
    this.onNextSurah,
    this.onPreviousSurah,
  });

  @override
  State<TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends State<TranslationView> {
  List<QuranAyah> _ayahs = [];
  bool _isLoading = true;
  String? _error;
  int? _highlightedAyah; // Track which ayah to highlight after jump

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  @override
  void didUpdateWidget(TranslationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah.number != widget.surah.number) {
      _loadSurah();
    } else if (oldWidget.initialAyah != widget.initialAyah &&
        widget.initialAyah != null) {
      _scrollToAyah(widget.initialAyah!);
    }
  }

  void _scrollToAyah(int ayahNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetIndex = _ayahs.indexWhere(
        (a) => a.numberInSurah == ayahNumber,
      );
      if (targetIndex != -1) {
        // Calculate offset based on whether Previous button is shown
        final hasPrevious = widget.surah.number > 1;
        final offset = hasPrevious
            ? 2
            : 1; // 1 for Header, +1 if Previous exists
        widget.itemScrollController.scrollTo(
          index: targetIndex + offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        // Highlight the ayah temporarily
        setState(() {
          _highlightedAyah = ayahNumber;
        });
        // Clear highlight after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _highlightedAyah = null;
            });
          }
        });
      }
    });
  }

  Future<void> _loadSurah() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<QuranProvider>(context, listen: false);
      final data = await provider.getSurahWithTranslation(widget.surah.number);

      if (mounted) {
        final allAyahs = data['ayahs'] as List<QuranAyah>? ?? [];
        setState(() {
          _ayahs = allAyahs;
          _isLoading = false;
        });

        if (widget.initialAyah != null) {
          _scrollToAyah(widget.initialAyah!);
        } else {
          // Jump to top (Header) safely after build
          // If previous button exists (index 0), header is at index 1
          final jumpIndex = widget.surah.number > 1 ? 1 : 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.itemScrollController.isAttached) {
              widget.itemScrollController.jumpTo(index: jumpIndex);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (_isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_error', style: TextStyle(color: textColor)),
                ElevatedButton(
                  onPressed: _loadSurah,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return ScrollablePositionedList.builder(
          itemScrollController: widget.itemScrollController,
          itemPositionsListener: widget.itemPositionsListener,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 120,
            bottom: 100,
          ),
          itemCount: _ayahs.length + 2 + (widget.surah.number > 1 ? 1 : 0),
          itemBuilder: (context, index) {
            final hasPrevious = widget.surah.number > 1;

            if (hasPrevious) {
              if (index == 0) {
                return _buildPreviousSurahCard(isDark, textColor, accentColor);
              }
              if (index == 1) {
                return _buildSurahHeader(isDark, textColor, accentColor);
              }
            } else {
              if (index == 0) {
                return _buildSurahHeader(isDark, textColor, accentColor);
              }
            }

            // Adjust index for footer check
            final footerIndex = _ayahs.length + (hasPrevious ? 2 : 1);
            if (index == footerIndex) {
              return _buildNextSurahCard(isDark, textColor, accentColor);
            }

            // Adjust index for ayahs
            final ayahIndex = index - (hasPrevious ? 2 : 1);
            if (ayahIndex < 0 || ayahIndex >= _ayahs.length) {
              return const SizedBox.shrink();
            }

            final ayah = _ayahs[ayahIndex];
            final isHighlighted = _highlightedAyah == ayah.numberInSurah;
            return _buildAyahCard(
              ayah,
              isDark: isDark,
              textColor: textColor,
              accentColor: accentColor,
              isHighlighted: isHighlighted,
            );
          },
        );
      },
    );
  }

  Widget _buildPreviousSurahCard(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    if (widget.onPreviousSurah == null) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 50,
          padding: const EdgeInsets.all(12),
          onTap: widget.onPreviousSurah!,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: accentColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildNextSurahCard(bool isDark, Color textColor, Color accentColor) {
    if (widget.onNextSurah == null) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 40),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 50,
          padding: const EdgeInsets.all(12),
          onTap: widget.onNextSurah!,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: accentColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahHeader(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      child: Column(
        children: [
          Text(
            widget.surah.name,
            style: TextStyle(
              fontFamily: 'Indopak',
              letterSpacing: 0,
              fontSize: 36,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.surah.englishName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.surah.englishNameTranslation,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                widget.surah.revelationType,
                Icons.location_on,
                isDark,
                textColor,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                '${widget.surah.numberOfAyahs} Ayahs',
                Icons.menu_book,
                isDark,
                textColor,
              ),
            ],
          ),
          if (widget.surah.number != 1 && widget.surah.number != 9) ...[
            const SizedBox(height: 24),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'Indopak',
                letterSpacing: 0,
                fontSize: 24,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String text,
    IconData icon,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard(
    QuranAyah ayah, {
    bool isHighlighted = false,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    return GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.surah.number}:${ayah.numberInSurah}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _showTafseer(ayah),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 20,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _copyAyah(ayah),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      size: 20,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _shareAyah(ayah),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ayah.text,
            style: TextStyle(
              fontFamily: 'Indopak',
              letterSpacing: 0,
              fontSize: 28,
              height: 2.0,
              color: textColor,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (ayah.translations != null)
            _buildTranslations(
              ayah.translations!,
              isDark,
              textColor,
              accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildTranslations(
    Map<String, String> translations,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        final selectedKeys = provider.selectedTranslationKeys;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Divider(),
            ...selectedKeys.map((key) {
              final translation = translations[key];
              if (translation == null || translation.isEmpty) {
                return const SizedBox.shrink();
              }

              final translationNames = {
                'basein': 'ဦးဘစိန်',
                'ghazi': 'ဃာဇီဟာရှင်မ်',
                'hashim': 'ဟာရှင်မ်တင်မြင့်',
              };

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        translationNames[key] ?? key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translation,
                      style: TextStyle(
                        fontFamily: 'Myanmar',
                        fontSize: 18,
                        height: 1.6,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showTafseer(QuranAyah ayah) {
    final ayahKey = '${widget.surah.number}:${ayah.numberInSurah}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedTafseerScreen(
          ayahKey: ayahKey,
          surahName: widget.surah.englishName,
          ayahNumber: ayah.numberInSurah,
        ),
      ),
    );
  }

  void _copyAyah(QuranAyah ayah) {
    Clipboard.setData(
      ClipboardData(
        text:
            '${ayah.text}\n\n[${widget.surah.englishName} ${widget.surah.number}:${ayah.numberInSurah}]',
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  void _shareAyah(QuranAyah ayah) {
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final translationNames = {
      'basein': 'ဦးဘစိန်',
      'ghazi': 'ဃာဇီဟာရှင်မ်',
      'hashim': 'ဟာရှင်မ်တင်မြင့်',
    };

    final translationKey = provider.selectedTranslationKey;
    final translation = ayah.translations?[translationKey] ?? '';
    final translatorName = translationNames[translationKey] ?? 'Translation';
    final reference =
        '${widget.surah.englishName} ${widget.surah.number}:${ayah.numberInSurah}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Provider.of<SettingsProvider>(context).isDarkMode;
        final textColor = GlassTheme.text(isDark);
        // final accentColor = GlassTheme.accent(isDark);

        return Container(
          decoration: BoxDecoration(
            color: GlassTheme.background(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: GlassTheme.glassBorder(isDark)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share Ayah',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                reference,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildShareOption(
                icon: Icons.text_fields,
                title: 'Arabic Only',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  SharePlus.instance.share(
                    ShareParams(text: '${ayah.text}\n\n[$reference]'),
                  );
                },
              ),
              if (translation.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.translate,
                  title: 'Translation Only ($translatorName)',
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(
                      ShareParams(text: '$translation\n\n[$reference]'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.library_books,
                  title: 'Arabic + Translation',
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${ayah.text}\n\n$translatorName:\n$translation\n\n[$reference]',
                      ),
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

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}

class AyahTranslationCarousel extends StatefulWidget {
  final Map<String, String> translations;
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const AyahTranslationCarousel({
    super.key,
    required this.translations,
    required this.isDark,
    required this.textColor,
    required this.accentColor,
  });

  @override
  State<AyahTranslationCarousel> createState() =>
      _AyahTranslationCarouselState();
}

class _AyahTranslationCarouselState extends State<AyahTranslationCarousel> {
  late PageController _pageController;
  late int _currentIndex;
  final List<String> _translationKeys = ['ghazi', 'basein', 'hashim'];
  final Map<String, String> _translationNames = {
    'basein': 'ဦးဘစိန်',
    'ghazi': 'ဃာဇီဟာရှင်မ်',
    'hashim': 'ဟာရှင်မ်တင်မြင့်',
  };

  @override
  void initState() {
    super.initState();
    // Initialize with the globally selected translation if possible, otherwise default to Ghazi (index 0)
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final initialKey = provider.selectedTranslationKey;
    var initialIndex = _translationKeys.indexOf(initialKey);
    if (initialIndex == -1) initialIndex = 0;

    _currentIndex = initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // Translation Name Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _translationNames[_translationKeys[_currentIndex]] ??
                _translationKeys[_currentIndex],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Carousel
        SizedBox(
          height: _calculateHeight(
            widget.translations[_translationKeys[_currentIndex]] ?? '',
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _translationKeys.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Sync with provider so share/copy uses correct translation
              final provider = Provider.of<QuranProvider>(
                context,
                listen: false,
              );
              provider.setTranslationKey(_translationKeys[index]);
            },
            itemBuilder: (context, index) {
              final key = _translationKeys[index];
              final translation = widget.translations[key] ?? '';
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Text(
                  translation,
                  style: TextStyle(
                    fontFamily: 'Myanmar',
                    fontSize: 19,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_translationKeys.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index
                    ? widget.accentColor
                    : widget.accentColor.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }

  double _calculateHeight(String text) {
    // Approximate height calculation based on text length
    // This is a simple heuristic; for perfect sizing, we'd need a TextPainter
    // but that can be expensive in a list.
    // Base height + (lines * line height)
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Myanmar',
          fontSize: 19,
          height: 1.8,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );
    // Assuming a reasonable width for the text (screen width - padding)
    // We can get the actual width from MediaQuery if needed, but hardcoding a safe estimate is often enough for this heuristic
    // or we can use a LayoutBuilder in the parent.
    // Let's use a rough estimate for now or better yet, let the PageView expand?
    // PageView requires a fixed height or expanded. Since we are in a Column (in AyahCard), we need a height.
    // Let's use LayoutBuilder to get constraints.

    // Actually, calculating height dynamically for PageView children is tricky.
    // A common workaround is to use an ExpandablePageView or similar package,
    // or just give it enough height.
    // For now, let's try a simpler approach:
    // We will use a constraint based on the text length.

    // Better approach: Use a Stack with Visibility/Opacity for smooth height transition?
    // Or just let the container size itself to the *current* content?
    // PageView doesn't auto-size.

    // Let's try a simpler UI first:
    // Instead of a full PageView which enforces same height,
    // maybe just use the GestureDetector swipe we had, but with the smooth animation we added?
    // The user said "swaping translation is not cool. its bad ux ui".
    // PageView is the standard "cool" swipe.

    // Let's use a TextPainter to get the height of the *current* text and animate the container height.

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 32 - 40; // Padding

    textPainter.layout(maxWidth: contentWidth);
    return textPainter.height + 20; // Buffer
  }
}
