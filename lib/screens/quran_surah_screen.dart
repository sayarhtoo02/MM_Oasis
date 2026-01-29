import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quran_surah.dart';
import '../models/quran_ayah.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import 'tafseer_screen.dart';

class QuranSurahScreen extends StatefulWidget {
  final QuranSurah surah;
  final int? scrollToAyah;

  const QuranSurahScreen({super.key, required this.surah, this.scrollToAyah});

  @override
  State<QuranSurahScreen> createState() => _QuranSurahScreenState();
}

class _QuranSurahScreenState extends State<QuranSurahScreen> {
  List<QuranAyah> _ayahs = [];
  bool _isLoading = true;
  String? _error;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadSurah();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisible = positions.first.index;
      if (mounted) {
        final shouldExpand = firstVisible == 0;
        if (_isHeaderExpanded != shouldExpand) {
          setState(() {
            _isHeaderExpanded = shouldExpand;
          });
        }
      }
    }
  }

  void _showSearchDialog(BuildContext context, Color textColor) {
    final surahController = TextEditingController();
    final ayahController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Go to Verse', style: TextStyle(color: textColor)),
        // Note: Dialog styling could be further improved with GlassTheme but avoiding deep refactor of dialogs for now
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: surahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Surah Number (1-114)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ayahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verse Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final surahNum = int.tryParse(surahController.text);
              final ayahNum = int.tryParse(ayahController.text);
              Navigator.pop(context);
              if (surahNum != null && ayahNum != null) {
                if (surahNum == widget.surah.number) {
                  _scrollToAyah(ayahNum);
                } else {
                  _navigateToSurah(surahNum, ayahNum);
                }
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _scrollToAyah(int ayahNumber) {
    final index = _ayahs.indexWhere((a) => a.numberInSurah == ayahNumber);
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToSurah(int surahNumber, int ayahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return;
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final surahs = provider.surahs;
    if (surahs.isEmpty) await provider.loadSurahs();
    if (!mounted) return;

    try {
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QuranSurahScreen(surah: surah, scrollToAyah: ayahNumber),
        ),
      );
    } catch (e) {
      // Handle error if surah not found
    }
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
        _ayahs = allAyahs;
        setState(() => _isLoading = false);

        if (widget.scrollToAyah != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final targetIndex = _ayahs.indexWhere(
              (a) => a.numberInSurah == widget.scrollToAyah,
            );
            if (targetIndex != -1) {
              _itemScrollController.jumpTo(index: targetIndex);
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

        return GlassScaffold(
          title: widget.surah.englishName,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: textColor),
              onPressed: () => _showSearchDialog(context, textColor),
              tooltip: 'Jump to Ayah',
            ),
          ],
          body: Column(
            children: [
              _buildSurahHeader(isDark, textColor),
              Expanded(child: _buildContent(isDark, textColor, accentColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurahHeader(bool isDark, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: _isHeaderExpanded ? 8 : 0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _isHeaderExpanded ? 20 : 12,
        vertical: _isHeaderExpanded ? 20 : 8,
      ),
      decoration: BoxDecoration(
        color: GlassTheme.glassGradient(isDark)[0].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_isHeaderExpanded ? 20 : 12),
        border: Border.all(color: GlassTheme.glassBorder(isDark)),
        boxShadow: GlassTheme.glassShadow(isDark),
      ),
      child: _isHeaderExpanded
          ? Column(
              children: [
                if (widget.surah.number != 9) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.3),
                            Colors.amber.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'Indopak',
                          fontSize: 26,
                          color: Colors.white,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(
                      widget.surah.revelationType,
                      Icons.location_on,
                      textColor,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      '${widget.surah.numberOfAyahs} Ayahs',
                      Icons.menu_book,
                      textColor,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.surah.name,
                  style: TextStyle(
                    fontFamily: 'Indopak',
                    letterSpacing: 0,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.surah.englishName} • ${widget.surah.numberOfAyahs} Ayahs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildContent(bool isDark, Color textColor, Color accentColor) {
    return _isLoading
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: textColor),
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  style: TextStyle(color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSurah,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : _ayahs.isEmpty
        ? Center(
            child: Text(
              'No ayahs found',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          )
        : ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: const EdgeInsets.all(16),
            itemCount: _ayahs.length,
            itemBuilder: (context, index) {
              final ayah = _ayahs[index];
              return _buildAyahCard(ayah, isDark, textColor, accentColor);
            },
          );
  }

  Widget _buildAyahCard(
    QuranAyah ayah,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.surah.number}:${ayah.numberInSurah}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.info_outline,
                      () => _showTafseer(ayah),
                      'Tafseer',
                      textColor,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.translate,
                      _showTranslationSelector,
                      'Translations',
                      textColor,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.copy,
                      () => _copyAyah(ayah),
                      'Copy',
                      textColor,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.share,
                      () => _shareAyah(ayah),
                      'Share',
                      textColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black12
                  : const Color(0xFFFFF8E1).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              ayah.text,
              style: TextStyle(
                fontFamily: 'Indopak',
                fontSize: 32,
                height: 2.3,
                letterSpacing: 0,
                color: isDark ? Colors.white : const Color(0xFF0D3B2E),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          if (ayah.translations != null)
            _buildTranslations(ayah.translations!, isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip,
    Color color,
  ) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildTranslations(
    Map<String, String> translations,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: translations.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            entry.value,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withValues(alpha: isDark ? 0.9 : 0.8),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTafseer(QuranAyah ayah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TafseerScreen(
          ayahKey: '${widget.surah.number}:${ayah.numberInSurah}',
          surahName: widget.surah.englishName,
          ayahNumber: ayah.numberInSurah,
        ),
      ),
    );
  }

  void _showTranslationSelector() {
    final translationNames = {
      'basein': 'ဦးဘစိန်ဘာသာပြန်',
      'ghazi': 'ဃာဇီဟာရှင်မ်ဘာသာပြန်',
      'hashim': 'ဟာရှင်မ်တင်မြင့်ဘာသာပြန်',
    };

    showDialog(
      context: context,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final isDark = settingsProvider.isDarkMode;
          return AlertDialog(
            backgroundColor: GlassTheme.background(isDark),
            title: Text(
              'Select Translation',
              style: TextStyle(color: GlassTheme.text(isDark)),
            ),
            content: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: translationNames.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(
                        entry.value,
                        style: TextStyle(color: GlassTheme.text(isDark)),
                      ),
                      activeColor: GlassTheme.accent(isDark),
                      value: entry.key,
                      groupValue: provider.selectedTranslationKey,
                      onChanged: (value) {
                        if (value != null) {
                          provider.setTranslationKey(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: GlassTheme.accent(isDark)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copyAyah(QuranAyah ayah) {
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final translationNames = {
      'basein': 'ဦးဘစိန်',
      'ghazi': 'ဃာဇီဟာရှင်မ်',
      'hashim': 'ဟာရှင်မ်တင်မြင့်',
    };
    final buffer = StringBuffer(ayah.text);
    if (ayah.translations != null) {
      final translationKey = provider.selectedTranslationKey;
      final translation = ayah.translations![translationKey];
      if (translation != null) {
        buffer.write('\n\n${translationNames[translationKey]}: $translation');
      }
    }
    buffer.write(
      '\n\n${widget.surah.englishName} ${widget.surah.number}:${ayah.numberInSurah}',
    );
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verse copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: GlassTheme.background(
            Provider.of<SettingsProvider>(context, listen: false).isDarkMode,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: GlassTheme.glassBorder(
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).isDarkMode,
              ),
            ),
          ),
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
                color: GlassTheme.text(
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).isDarkMode,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reference,
              style: TextStyle(
                fontSize: 14,
                color: GlassTheme.text(
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).isDarkMode,
                ).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildShareOption(
              icon: Icons.text_fields,
              title: 'Arabic Only',
              subtitle: 'Share Quranic text only',
              onTap: () {
                Navigator.pop(context);
                // ignore: deprecated_member_use
                Share.share('${ayah.text}\n\n[$reference]');
              },
            ),
            const SizedBox(height: 12),
            if (translation.isNotEmpty)
              _buildShareOption(
                icon: Icons.translate,
                title: 'Translation Only',
                subtitle: translatorName,
                onTap: () {
                  Navigator.pop(context);
                  // ignore: deprecated_member_use
                  Share.share('$translation\n\n[$reference]');
                },
              ),
            if (translation.isNotEmpty) const SizedBox(height: 12),
            if (translation.isNotEmpty)
              _buildShareOption(
                icon: Icons.library_books,
                title: 'Arabic + Translation',
                subtitle: 'Share both together',
                onTap: () {
                  Navigator.pop(context);
                  final content = StringBuffer();
                  content.writeln(ayah.text);
                  content.writeln();
                  content.writeln('$translatorName:');
                  content.writeln(translation);
                  content.writeln();
                  content.write('[$reference]');
                  // ignore: deprecated_member_use
                  Share.share(content.toString());
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: GlassTheme.glassBorder(
              Provider.of<SettingsProvider>(context, listen: false).isDarkMode,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GlassTheme.accent(
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).isDarkMode,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: GlassTheme.accent(
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).isDarkMode,
                ),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GlassTheme.text(
                        Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).isDarkMode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlassTheme.text(
                        Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).isDarkMode,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
