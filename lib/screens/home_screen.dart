import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/dua_provider.dart';
import '../screens/dua_detail_screen.dart';
import '../services/dua_repository.dart';
import '../models/dua_model.dart';
import '../utils/haptic_feedback_helper.dart';
import '../utils/animation_helpers.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/screens/dua_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateWidgetWithLastReadDua(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateWidgetWithLastReadDua() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final lastReadDua = settingsProvider.appSettings.duaPreferences.lastReadDua;
    if (lastReadDua != null &&
        settingsProvider.appSettings.widgetSettings.isHomeScreenWidgetEnabled) {
      settingsProvider.updateWidgetsWithDua(lastReadDua);
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
                _buildHeader(isDark, textColor, accentColor),
                Expanded(
                  child: _buildManzilList(isDark, textColor, accentColor),
                ),
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
              Icons.auto_stories_rounded,
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
                  'Munajat-e-Maqbool',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '7 Manzils • Daily Duas',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final lastReadDua =
                  settingsProvider.appSettings.duaPreferences.lastReadDua;
              if (lastReadDua != null) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.bookmark_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                    tooltip: 'Continue Reading',
                    onPressed: () async {
                      HapticFeedbackHelper.buttonPress();
                      final duaRepository = DuaRepository();
                      final manzilDuas = await duaRepository.getDuasByManzil(
                        lastReadDua.manzilNumber,
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        AnimationHelpers.slideTransition(
                          DuaDetailScreen(
                            initialDua: lastReadDua,
                            manzilDuas: manzilDuas,
                          ),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Container(
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: textColor, size: 22),
              onPressed: () {
                HapticFeedbackHelper.buttonPress();
                Navigator.pushNamed(context, '/search');
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManzilList(bool isDark, Color textColor, Color accentColor) {
    final List<Map<String, dynamic>> manzils = [
      {
        'day': 'Saturday',
        'dayArabic': 'السبت',
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'day': 'Sunday',
        'dayArabic': 'الأحد',
        'icon': Icons.brightness_5,
        'color': const Color(0xFFFFBE76),
      },
      {
        'day': 'Monday',
        'dayArabic': 'الإثنين',
        'icon': Icons.brightness_6,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'day': 'Tuesday',
        'dayArabic': 'الثلاثاء',
        'icon': Icons.brightness_7,
        'color': const Color(0xFF45B7D1),
      },
      {
        'day': 'Wednesday',
        'dayArabic': 'الأربعاء',
        'icon': Icons.wb_cloudy_outlined,
        'color': const Color(0xFF96CEB4),
      },
      {
        'day': 'Thursday',
        'dayArabic': 'الخميس',
        'icon': Icons.nights_stay_outlined,
        'color': const Color(0xFF9B59B6),
      },
      {
        'day': 'Friday',
        'dayArabic': 'الجمعة',
        'icon': 'assets/icons/icon_masjid.png',
        'color': accentColor,
      },
    ];

    final int currentDay = DateTime.now().weekday;
    int todayManzilIndex;
    if (currentDay == DateTime.saturday) {
      todayManzilIndex = 0;
    } else if (currentDay == DateTime.sunday) {
      todayManzilIndex = 1;
    } else {
      todayManzilIndex = currentDay + 1;
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedbackHelper.lightImpact();
        final duaProvider = Provider.of<DuaProvider>(context, listen: false);
        await duaProvider.loadAllDuas();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 100,
        ),
        itemCount: manzils.length,
        itemBuilder: (context, index) {
          final manzil = manzils[index];
          final int manzilNumber = index + 1;
          final bool isToday = index == todayManzilIndex;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = (index * 0.1).clamp(0.0, 0.6);
              final rawValue = (_animationController.value - delay).clamp(
                0.0,
                1.0,
              );
              final animValue = Curves.easeOutCubic.transform(rawValue);
              return Transform.translate(
                offset: Offset(0, 30 * (1 - animValue)),
                child: Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildManzilCard(
              manzilNumber: manzilNumber,
              manzilInfo: manzil,
              isToday: isToday,
              isDark: isDark,
              textColor: textColor,
              accentColor: accentColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildManzilCard({
    required int manzilNumber,
    required Map<String, dynamic> manzilInfo,
    required bool isToday,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    final Color cardColor = manzilInfo['color'] as Color;

    return Consumer2<SettingsProvider, DuaProvider>(
      builder: (context, settingsProvider, duaProvider, child) {
        final String? lastReadDuaId = settingsProvider
            .appSettings
            .duaPreferences
            .manzilProgress[manzilNumber];
        final manzilDuas = duaProvider.allDuas
            .where((d) => d.manzilNumber == manzilNumber)
            .toList();
        final Dua? lastReadDua = lastReadDuaId != null && manzilDuas.isNotEmpty
            ? manzilDuas.firstWhere(
                (d) => d.id == lastReadDuaId,
                orElse: () => manzilDuas.first,
              )
            : null;

        final int currentProgress = lastReadDua != null
            ? manzilDuas.indexWhere((d) => d.id == lastReadDua.id) + 1
            : 0;
        final int totalDuas = manzilDuas.length;
        final double progress = totalDuas > 0 ? currentProgress / totalDuas : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 20,
            padding: EdgeInsets.zero,
            onTap: () async {
              HapticFeedbackHelper.lightImpact();
              final duaRepository = DuaRepository();
              final List<Dua> manzilDuasList = await duaRepository
                  .getDuasByManzil(manzilNumber);
              if (!context.mounted) return;
              if (lastReadDua != null) {
                Navigator.push(
                  context,
                  AnimationHelpers.slideTransition(
                    DuaDetailScreen(
                      initialDua: lastReadDua,
                      manzilDuas: manzilDuasList,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DuaListScreen(manzilNumber: manzilNumber),
                  ),
                );
              }
            },
            child: Container(
              decoration: isToday
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cardColor, cardColor.withValues(alpha: 0.85)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white.withValues(alpha: 0.2)
                            : cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          manzilInfo['icon'] is IconData
                              ? Icon(
                                  manzilInfo['icon'] as IconData,
                                  color: isToday ? Colors.white : cardColor,
                                  size: 28,
                                )
                              : Image.asset(
                                  manzilInfo['icon'] as String,
                                  width: 28,
                                  height: 28,
                                ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isToday ? Colors.white : cardColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$manzilNumber',
                                  style: TextStyle(
                                    color: isToday ? cardColor : Colors.white,
                                    fontSize: 11,
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
                          Row(
                            children: [
                              Text(
                                'Manzil $manzilNumber',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : textColor,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: TextStyle(
                                      color: cardColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            manzilInfo['day'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: isToday
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: isToday
                                            ? Colors.white.withValues(
                                                alpha: 0.3,
                                              )
                                            : cardColor.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation(
                                          isToday ? Colors.white : cardColor,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$currentProgress/$totalDuas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? Colors.white
                                          : textColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastReadDua != null
                                    ? 'Continue Reading'
                                    : 'Start Reading',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isToday
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : textColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white.withValues(alpha: 0.2)
                            : cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isToday ? Colors.white : cardColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
