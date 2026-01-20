// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hadith_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hadith_service.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import 'hadith_section_screen.dart';

class HadithBookScreen extends StatefulWidget {
  final String bookKey;

  const HadithBookScreen({super.key, required this.bookKey});

  @override
  State<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends State<HadithBookScreen> {
  void _showSearchDialog() {
    final hadithController = TextEditingController();
    final isDark = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.background(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Search Hadith', style: TextStyle(color: textColor)),
        content: TextField(
          controller: hadithController,
          keyboardType: TextInputType.text,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Hadith Number',
            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(
              Icons.search,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () async {
              final hadithNum = hadithController.text.trim();
              Navigator.pop(context);
              if (hadithNum.isNotEmpty) {
                final provider = context.read<HadithProvider>();
                final service = HadithService();
                try {
                  final hadith = await service.getHadithByNumber(
                    widget.bookKey,
                    hadithNum,
                  );
                  if (hadith != null && mounted) {
                    await provider.loadChapter(hadith.chapterId);
                    if (mounted) {
                      final book = provider.currentBook;
                      final chapter = book?.chapters.firstWhere(
                        (c) => c.id == hadith.chapterId,
                        orElse: () => book.chapters.first,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HadithSectionScreen(
                            chapterId: hadith.chapterId,
                            chapterName: (chapter?.english.isNotEmpty == true)
                                ? chapter!.english
                                : (chapter?.arabic ?? 'Chapter'),
                            scrollToHadith: hadith.idInBook,
                          ),
                        ),
                      );
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hadith not found')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Search', style: TextStyle(color: Colors.white)),
          ),
        ],
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

        return GlassScaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(isDark, textColor),
                _buildBookHeader(isDark, textColor),
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
          Container(
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: textColor),
              onPressed: _showSearchDialog,
            ),
          ),
          const SizedBox(width: 8),
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
              onSelected: (lang) => provider.changeLanguage(lang),
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

  Widget _buildBookHeader(bool isDark, Color textColor) {
    return Consumer<HadithProvider>(
      builder: (context, provider, _) {
        final book = provider.currentBook;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 20,
            child: Column(
              children: [
                Text(
                  book?.name ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${book?.chapters.length ?? 0} Chapters',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark, Color textColor, Color accentColor) {
    return Consumer<HadithProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        final book = provider.currentBook;
        if (book == null) {
          return Center(
            child: Text(
              'Failed to load book',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: book.chapters.length,
          itemBuilder: (context, index) {
            final chapter = book.chapters[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                isDark: isDark,
                borderRadius: 16,
                padding: EdgeInsets.zero,
                onTap: () {
                  provider.loadChapter(chapter.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithSectionScreen(
                        chapterId: chapter.id,
                        chapterName:
                            (provider.selectedLanguage == 'ara' ||
                                chapter.english.isEmpty)
                            ? chapter.arabic
                            : chapter.english,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                              provider.selectedLanguage == 'ara' ||
                                      chapter.english.isEmpty
                                  ? chapter.arabic
                                  : chapter.english,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (provider.selectedLanguage != 'ara' &&
                                chapter.english.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  chapter.arabic,
                                  style: TextStyle(
                                    fontFamily: 'Indopak',
                                    fontSize: 14,
                                    letterSpacing: 0,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
