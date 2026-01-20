import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/dua_detail_screen.dart';
import '../services/dua_repository.dart';
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen_components/custom_collections_tab.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../config/glass_theme.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final favoriteDuas =
            settingsProvider.appSettings.duaPreferences.favoriteDuas;

        return GlassScaffold(
          body: Column(
            children: [
              GlassAppBar(title: 'Bookmarks & Collections', isDark: isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassTheme.glassBorder(isDark)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: accentColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  labelColor: accentColor,
                  unselectedLabelColor: textColor.withValues(alpha: 0.6),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'Bookmarks'),
                    Tab(text: 'Custom Collections'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Bookmarks Tab Content
                    favoriteDuas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 64,
                                  color: textColor.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookmarked Duas yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add some from the Dua Detail screen!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: favoriteDuas.length,
                            itemBuilder: (context, index) {
                              final dua = favoriteDuas[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  isDark: isDark,
                                  borderRadius: 16,
                                  padding: EdgeInsets.zero,
                                  onTap: () async {
                                    final duaRepository = DuaRepository();
                                    final manzilDuas = await duaRepository
                                        .getDuasByManzil(dua.manzilNumber);
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DuaDetailScreen(
                                          initialDua: dua,
                                          manzilDuas: manzilDuas,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: accentColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: accentColor.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                'Manzil ${dua.manzilNumber}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Day ${dua.day}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          dua.arabicText,
                                          textAlign: TextAlign.justify,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            fontFamily: 'Indopak',
                                            fontSize:
                                                28 *
                                                settingsProvider
                                                    .appSettings
                                                    .displaySettings
                                                    .arabicFontSizeMultiplier,
                                            height: 1.5,
                                            letterSpacing: 0,
                                            color: textColor,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          settingsProvider
                                                      .appSettings
                                                      .languageSettings
                                                      .selectedLanguage ==
                                                  'en'
                                              ? dua.translations.english
                                              : settingsProvider
                                                        .appSettings
                                                        .languageSettings
                                                        .selectedLanguage ==
                                                    'my'
                                              ? dua.translations.burmese
                                              : dua.translations.urdu,
                                          style: TextStyle(
                                            fontSize:
                                                14 *
                                                settingsProvider
                                                    .appSettings
                                                    .displaySettings
                                                    .translationFontSizeMultiplier,
                                            color: textColor.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    // Custom Collections Tab Content
                    const CustomCollectionsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
