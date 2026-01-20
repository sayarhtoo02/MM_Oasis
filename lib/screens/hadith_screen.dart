import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hadith_provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import 'hadith_book_screen.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _books = [
    {
      'key': 'bukhari',
      'name': 'Sahih al Bukhari',
      'arabicName': 'صحيح البخاري',
      'hadithCount': '7563',
      'author': 'Imam Bukhari',
      'color': const Color(0xFFE74C3C),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'key': 'muslim',
      'name': 'Sahih Muslim',
      'arabicName': 'صحيح مسلم',
      'hadithCount': '7563',
      'author': 'Imam Muslim',
      'color': const Color(0xFF3498DB),
      'icon': Icons.menu_book_rounded,
    },
    {
      'key': 'abudawud',
      'name': 'Sunan Abu Dawud',
      'arabicName': 'سنن أبي داود',
      'hadithCount': '5274',
      'author': 'Imam Abu Dawud',
      'color': const Color(0xFF2ECC71),
      'icon': Icons.book_rounded,
    },
    {
      'key': 'tirmidhi',
      'name': 'Jami` at-Tirmidhi',
      'arabicName': 'جامع الترمذي',
      'hadithCount': '3956',
      'author': 'Imam Tirmidhi',
      'color': const Color(0xFF9B59B6),
      'icon': Icons.library_books_rounded,
    },
    {
      'key': 'nasai',
      'name': "Sunan an-Nasa'i",
      'arabicName': 'سنن النسائي',
      'hadithCount': '5758',
      'author': 'Imam Nasai',
      'color': const Color(0xFFF39C12),
      'icon': Icons.chrome_reader_mode_rounded,
    },
    {
      'key': 'ibnmajah',
      'name': 'Sunan Ibn Majah',
      'arabicName': 'سنن ابن ماجه',
      'hadithCount': '4332',
      'author': 'Imam Ibn Majah',
      'color': const Color(0xFF1ABC9C),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'key': 'malik',
      'name': 'Muwatta Malik',
      'arabicName': 'موطأ مالك',
      'hadithCount': '1832',
      'author': 'Imam Malik',
      'color': const Color(0xFFE91E63),
      'icon': Icons.class_rounded,
    },
    {
      'key': 'ahmed',
      'name': 'Musnad Ahmed',
      'arabicName': 'مسند أحمد',
      'hadithCount': '27647',
      'author': 'Imam Ahmed',
      'color': const Color(0xFF00BCD4),
      'icon': Icons.collections_bookmark_rounded,
    },
    {
      'key': 'darimi',
      'name': 'Sunan Darimi',
      'arabicName': 'سنن الدارمي',
      'hadithCount': '3503',
      'author': 'Imam Darimi',
      'color': const Color(0xFF795548),
      'icon': Icons.bookmark_border_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, textColor, accentColor),
                Expanded(child: _buildBookList(isDark, textColor, accentColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.library_books_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hadith Collections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_books.length} Books Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Consumer<HadithProvider>(
            builder: (context, provider, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                initialValue: provider.selectedLanguage,
                padding: EdgeInsets.zero,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, color: textColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _getLanguageName(provider.selectedLanguage),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                onSelected: (lang) => provider.changeLanguage(lang),
                itemBuilder: (context) => [
                  _buildLanguageItem('ara', 'العربية', 'Arabic', textColor),
                  _buildLanguageItem('eng', 'English', 'English', textColor),
                  _buildLanguageItem('my', 'မြန်မာ', 'Burmese', textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ara':
        return 'AR';
      case 'eng':
        return 'EN';
      case 'my':
        return 'MY';
      default:
        return 'EN';
    }
  }

  PopupMenuItem<String> _buildLanguageItem(
    String value,
    String nativeName,
    String englishName,
    Color textColor,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                value.toUpperCase().substring(0, 2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nativeName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nativeName != englishName)
                Text(
                  englishName,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(bool isDark, Color textColor, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.1;
            final rawValue = (_animationController.value - delay).clamp(
              0.0,
              1.0,
            );
            final animValue = Curves.easeOutCubic.transform(rawValue);
            final opacity = animValue.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animValue)),
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: _buildBookCard(book, index, isDark, textColor),
        );
      },
    );
  }

  Widget _buildBookCard(
    Map<String, dynamic> book,
    int index,
    bool isDark,
    Color textColor,
  ) {
    final Color bookColor = book['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 20,
        padding: EdgeInsets.zero,
        onTap: () {
          context.read<HadithProvider>().loadBook(book['key'] as String);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HadithBookScreen(bookKey: book['key'] as String),
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
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bookColor.withValues(alpha: 0.15),
                      bookColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: bookColor.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(book['icon'] as IconData, color: bookColor, size: 32),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: bookColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: bookColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['name'] as String,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['arabicName'] as String,
                      style: TextStyle(
                        fontFamily: 'Indopak',
                        fontSize: 16,
                        letterSpacing: 0,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.format_list_numbered,
                          label: '${book['hadithCount']} Hadiths',
                          color: bookColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bookColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: bookColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
