import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/quran_provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'quran_reading_screen.dart';
import 'khatam_planner_screen.dart';
import '../services/reading_stats_service.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isHeaderExpanded = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurahs();
    });
  }

  void _onScroll() {
    final shouldExpand = _scrollController.offset < 50;
    if (_isHeaderExpanded != shouldExpand) {
      setState(() {
        _isHeaderExpanded = shouldExpand;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final isDark = settings.isDarkMode;
          final textColor = GlassTheme.text(isDark);
          final accentColor = GlassTheme.accent(isDark);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildSliverAppBar(textColor, isDark),
                if (!_isSearching)
                  _buildDashboardHeader(isDark, textColor, accentColor),
                if (_isSearching) _buildSearchBar(isDark),
                _buildTabBar(isDark, accentColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSurahList(isDark, textColor, accentColor),
                      _buildJuzList(
                        isDark,
                        textColor,
                        accentColor,
                      ), // We'll update this method too if needed
                      _buildBookmarksList(
                        isDark,
                        textColor,
                        accentColor,
                      ), // And this one
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Floating Continue Reading Button
      floatingActionButton: Consumer2<QuranProvider, SettingsProvider>(
        builder: (context, quranProvider, settingsProvider, _) {
          final lastRead = quranProvider.lastRead;
          final isDark = settingsProvider.isDarkMode;
          final accentColor = GlassTheme.accent(isDark);

          if (lastRead == null || _isSearching) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuranReadingScreen(
                      initialSurahNumber: lastRead['surahNumber'],
                      initialAyahNumber: lastRead['ayahNumber'],
                      initialPageNumber: lastRead['pageNumber'],
                    ),
                  ),
                );
              },
              backgroundColor: accentColor,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Image.asset(
            'assets/images/app_icon.png',
            height: 32,
            width: 32,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.menu_book, color: textColor),
          ),
          const SizedBox(width: 12),
          Text(
            'Al-Quran',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    // Only keeping the CrossFade logic but simplifying content for brevity in diff
    // In a real scenario we'd refactor the inner containers to GlassCards too if needed,
    // but the existing gradient container looks fine as a specialized hero element.
    // We just need to update text styles if they were hardcoded to white (which they are) - that's fine.
    // We will update the QuickAccess and LastRead to be GlassCards.

    final hijriDate = HijriCalendar.now();
    final gregorianDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: _isHeaderExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Islamic Date Card
            GlassCard(
              isDark: isDark,
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              // Use a subtle tint for the hero card to make it pop slightly more
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 100,
                        color: textColor,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} AH',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gregorianDate,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            'assets/icons/icon_masjid.png',
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildReadingStatsCard(isDark, textColor, accentColor),
            const SizedBox(height: 16),
            _buildLastReadCard(isDark, textColor, accentColor),
            _buildQuickAccessSection(isDark, textColor, accentColor),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }

  Widget _buildReadingStatsCard(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReadingStatsService.getProgressSummary(),
      builder: (context, snapshot) {
        final totalRead = snapshot.data?['total_verses_read'] ?? 0;
        final percentage = snapshot.data?['percentage'] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KhatamPlannerScreen(),
                ),
              ).then((_) => setState(() {})); // Refresh stats on return
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_graph_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: textColor.withValues(alpha: 0.1),
                    color: accentColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalRead of 6236 verses read',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastReadCard(bool isDark, Color textColor, Color accentColor) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        final lastRead = provider.lastRead;
        if (lastRead == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history_edu, color: accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Read',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastRead['surahName'] ?? 'Surah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Ayah ${lastRead['ayahNumber']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranReadingScreen(
                          initialSurahNumber: lastRead['surahNumber'],
                          initialAyahNumber: lastRead['ayahNumber'],
                          initialPageNumber: lastRead['pageNumber'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black, // Dark text on Gold
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessSection(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildQuickLinkCard('Yaseen', 36, isDark, textColor, accentColor),
              _buildQuickLinkCard('Mulk', 67, isDark, textColor, accentColor),
              _buildQuickLinkCard('Kahf', 18, isDark, textColor, accentColor),
              _buildQuickLinkCard('Waqiah', 56, isDark, textColor, accentColor),
              _buildQuickLinkCard('Rahman', 55, isDark, textColor, accentColor),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQuickLinkCard(
    String name,
    int surahNumber,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuranReadingScreen(initialSurahNumber: surahNumber),
            ),
          );
        },
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              'Surah $surahNumber',
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        padding: EdgeInsets.zero,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: GlassTheme.text(isDark)),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            if (value.length > 2) {
              context.read<QuranProvider>().search(value);
            } else {
              context.read<QuranProvider>().clearSearch();
            }
          },
          decoration: InputDecoration(
            hintText: 'Search Surah by name or number...',
            hintStyle: TextStyle(
              color: GlassTheme.text(isDark).withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: GlassTheme.text(isDark).withValues(alpha: 0.7),
            ),
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark, Color accentColor) {
    // Glassy TabBar
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.black, // Active tab text color (Gold bg)
        unselectedLabelColor: GlassTheme.text(isDark).withValues(alpha: 0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Surah'),
          Tab(text: 'Juz'),
          Tab(text: 'Bookmarks'),
        ],
      ),
    );
  }

  Widget _buildSurahList(bool isDark, Color textColor, Color accentColor) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        // If searching and we have text results, show them
        if (_isSearching && _searchQuery.isNotEmpty) {
          if (provider.isSearching) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          // Combine Surah matches and Ayah matches
          final surahMatches = provider.surahs.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.englishName.toLowerCase().contains(query) ||
                s.name.contains(query) ||
                s.number.toString() == query;
          }).toList();

          final ayahMatches = provider.searchResults;

          if (surahMatches.isEmpty && ayahMatches.isEmpty) {
            return Center(
              child: Text(
                'No results found',
                style: TextStyle(color: textColor),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 180,
            ),
            children: [
              if (surahMatches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Surahs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                ...surahMatches.map(
                  (surah) =>
                      _buildSurahCard(surah, isDark, textColor, accentColor),
                ),
                const SizedBox(height: 16),
              ],
              if (ayahMatches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ayahs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                ...ayahMatches.map(
                  (match) => _buildAyahResultCard(
                    match,
                    isDark,
                    textColor,
                    accentColor,
                  ),
                ),
              ],
            ],
          );
        }

        // Default Surah List
        final surahs = provider.surahs;

        if (surahs.isEmpty) {
          return Center(
            child: Text('No Surahs found', style: TextStyle(color: textColor)),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 180,
          ),
          itemCount: surahs.length,
          itemBuilder: (context, index) {
            return _buildSurahCard(
              surahs[index],
              isDark,
              textColor,
              accentColor,
            );
          },
        );
      },
    );
  }

  Widget _buildSurahCard(
    dynamic surah,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        // Calculate progress if this surah has been read
        double progress = 0.0;
        bool hasProgress = false;
        if (provider.lastRead != null &&
            provider.lastRead!['surahNumber'] == surah.number) {
          final lastAyah = provider.lastRead!['ayahNumber'] as int? ?? 0;
          progress = lastAyah / surah.numberOfAyahs;
          hasProgress = true;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 16,
            padding: EdgeInsets.zero, // Padding handled inside Column
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuranReadingScreen(initialSurahNumber: surah.number),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Surah Number with progress ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (hasProgress)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                backgroundColor: textColor.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentColor,
                                ),
                              ),
                            ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: hasProgress
                                  ? Colors.transparent
                                  : textColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${surah.number}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hasProgress ? accentColor : textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Surah Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.englishName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${surah.revelationType} • ${surah.numberOfAyahs} Ayahs',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                if (hasProgress) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Arabic Name
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontFamily: 'Indopak',
                          letterSpacing: 0,
                          fontSize: 20,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahResultCard(
    Map<String, dynamic> match,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final surahNum = match['surah'] as int;
    final ayahNum = match['ayah'] as int;
    final text = match['text'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuranReadingScreen(
                initialSurahNumber: surahNum,
                initialAyahNumber: ayahNum,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    'Surah $surahNum : Ayah $ayahNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 3,
              style: TextStyle(color: textColor, height: 1.5),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzList(bool isDark, Color textColor, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 180),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 16,
            padding: EdgeInsets.zero,
            onTap: () {
              final page = (juzNumber - 1) * 20 + 2; // Approximate
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranReadingScreen(
                    initialSurahNumber: 1, // Dummy
                    initialPageNumber: page,
                  ),
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$juzNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              title: Text(
                'Juz $juzNumber',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList(bool isDark, Color textColor, Color accentColor) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        final bookmarks = provider.bookmarks;

        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 180,
          ),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                isDark: isDark,
                borderRadius: 16,
                padding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuranReadingScreen(
                        initialSurahNumber: bookmark['surahNumber'],
                        initialAyahNumber: bookmark['ayahNumber'],
                        initialPageNumber: bookmark['pageNumber'],
                      ),
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Icon(Icons.bookmark, color: accentColor),
                  title: Text(
                    bookmark['surahName'] ?? 'Surah ${bookmark['surahNumber']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Ayah ${bookmark['ayahNumber']}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      provider.toggleBookmark(
                        surahNumber: bookmark['surahNumber'],
                        ayahNumber: bookmark['ayahNumber'],
                        surahName: bookmark['surahName'],
                      );
                    },
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
