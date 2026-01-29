import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/prayer_times_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_screen.dart';
import 'package:munajat_e_maqbool_app/screens/allah_names_screen.dart';
import 'package:munajat_e_maqbool_app/screens/donation_screen.dart';
import 'package:munajat_e_maqbool_app/screens/ramadan_screen.dart';
import 'package:munajat_e_maqbool_app/screens/main_app_shell.dart';
import 'package:munajat_e_maqbool_app/services/hijri_service.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';

import 'package:adhan/adhan.dart';
import 'package:munajat_e_maqbool_app/services/prayer_time_service.dart';

import 'package:munajat_e_maqbool_app/screens/qibla_finder_screen.dart';

import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_list_screen.dart';
import 'package:munajat_e_maqbool_app/widgets/ads_banner_widget.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Al-Quran',
      'asset': 'assets/icons/icon_quran.png',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
    },
    {
      'title': 'Hadith',
      'asset': 'assets/icons/icon_hadith.png',
      'color': const Color(0xFF2196F3),
      'gradient': [const Color(0xFF2196F3), const Color(0xFF1565C0)],
    },
    {
      'title': 'Dua',
      'asset': 'assets/icons/icon_dua.png',
      'color': const Color(0xFFE91E63),
      'gradient': [const Color(0xFFE91E63), const Color(0xFFC2185B)],
    },
    {
      'title': 'Tasbih',
      'asset': 'assets/icons/icon_tasbih.png',
      'color': const Color(0xFF9C27B0),
      'gradient': [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
    },
    {
      'title': 'Ramadan',
      'asset':
          'assets/icons/icon_ramadan.png', // Ensure this asset exists or use a placeholder
      'color': const Color(0xFF795548),
      'gradient': [const Color(0xFF795548), const Color(0xFF5D4037)],
    },
    {
      'title': '99 Names',
      'asset': 'assets/icons/icon_99_names.png',
      'color': const Color(0xFFFF9800),
      'gradient': [const Color(0xFFFF9800), const Color(0xFFE65100)],
    },
    {
      'title': 'Sunnah',
      'asset': 'assets/icons/icon_sunnah.png',
      'color': const Color(0xFF009688),
      'gradient': [const Color(0xFF009688), const Color(0xFF00695C)],
    },
    {
      'title': 'Qibla',
      'asset': 'assets/icons/icon_qibla.png',
      'color': const Color(0xFF607D8B),
      'gradient': [const Color(0xFF607D8B), const Color(0xFF455A64)],
    },
    {
      'title': 'Donate',
      'asset': 'assets/icons/icon_donation.png',
      'color': const Color(0xFF00BCD4),
      'gradient': [const Color(0xFF00BCD4), const Color(0xFF00838F)],
    },
    {
      'title': 'Halal Shop',
      'asset': 'assets/icons/icon_halal_shop.png',
      'color': const Color(0xFF8BC34A),
      'gradient': [const Color(0xFF8BC34A), const Color(0xFF689F38)],
    },
    {
      'title': 'Masjid',
      'asset': 'assets/icons/icon_masjid.png',
      'color': const Color(0xFF00897B),
      'gradient': [const Color(0xFF00897B), const Color(0xFF00695C)],
    },
  ];

  @override
  void initState() {
    super.initState();
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
    return GlassScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final isDark = settingsProvider.isDarkMode;

            // Text Colors from GlassTheme
            final mainTextColor = GlassTheme.text(isDark);
            final accentColor = GlassTheme.accent(isDark);

            return Column(
              children: [
                _buildHeader(
                  settingsProvider,
                  mainTextColor,
                  accentColor,
                  isDark,
                ),
                // Ads Banner (non-intrusive carousel)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AdsBannerWidget(),
                ),
                _buildHeroCard(mainTextColor, accentColor, isDark),
                _buildFeatureSection(mainTextColor, accentColor, isDark),
                _buildPrayerTimesCard(
                  settingsProvider,
                  mainTextColor,
                  accentColor,
                  isDark,
                ),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    SettingsProvider settings,
    Color tealColor,
    Color goldColor,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = Curves.easeOutCubic.transform(
          _animationController.value,
        );
        return Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // Profile Avatar with gradient border
            GestureDetector(
              onTap: () {
                HapticFeedbackHelper.lightImpact();
                mainAppShellKey.currentState?.switchToTab(6);
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0B40A), Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: tealColor,
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFE0B40A),
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Assalamu Alaikum',
                        style: TextStyle(
                          color: tealColor, // Dark Text
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: tealColor.withValues(alpha: 0.6), // Dark Icon
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        HijriService.getHijriDate(),
                        style: TextStyle(
                          color: tealColor.withValues(alpha: 0.7), // Dark Text
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notification Button
            Container(
              decoration: BoxDecoration(
                color: tealColor.withValues(alpha: 0.05), // Light tint
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tealColor.withValues(alpha: 0.1),
                ), // Border
              ),
              child: IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: tealColor, // Dark Icon
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedbackHelper.lightImpact();
                  mainAppShellKey.currentState?.switchToTab(6);
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Color tealColor, Color goldColor, bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = 0.1;
        final rawValue = ((_animationController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        final animValue = Curves.easeOutCubic.transform(rawValue);
        return Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.3),
                  ],
            stops: const [0.0, 1.0],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.60),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : tealColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            color: Colors.transparent, // Transparent for glass effect
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tealColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✨ Daily Reminder',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tealColor, // Dark Text
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Remember Allah\nIn Every Moment',
                        style: TextStyle(
                          color: tealColor, // Dark Text
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          HapticFeedbackHelper.buttonPress();
                          Navigator.pushNamed(context, '/munajat_main');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      goldColor,
                                      goldColor.withValues(alpha: 0.8),
                                    ]
                                  : [tealColor, const Color(0xFF1B4D3E)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? goldColor.withValues(alpha: 0.3)
                                    : tealColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Reading',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF0D3B2E)
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: isDark
                                    ? const Color(0xFF0D3B2E)
                                    : Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tealColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: tealColor, // Dark Icon
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(Color tealColor, Color goldColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Access',
                style: TextStyle(
                  color: tealColor, // Dark Text
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tealColor.withValues(alpha: 0.05), // Light tint
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tealColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFFE0B40A),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_features.length} Features',
                      style: TextStyle(
                        color: tealColor.withValues(alpha: 0.8), // Dark Text
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final delay = 0.3 + (index * 0.05);
                  final rawValue =
                      ((_animationController.value - delay) / (1 - delay))
                          .clamp(0.0, 1.0);
                  final animValue = Curves.easeOutCubic.transform(rawValue);
                  return Transform.scale(
                    scale: 0.8 + (0.2 * animValue),
                    child: Opacity(
                      opacity: animValue.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildFeatureCard(_features[index], tealColor, isDark),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    Map<String, dynamic> feature,
    Color tealColor,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _navigateToFeature(feature['title'] as String),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glass card with icon only
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    // Glass Body
                    GlassCard(
                      isDark: isDark,
                      borderRadius: 100, // Fully circular
                      padding: const EdgeInsets.all(
                        10,
                      ), // Slightly more padding for circles
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Scale icon to roughly 70% of card width
                          final iconSize = constraints.maxWidth * 0.70;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (feature['asset'] != null)
                                  Image.asset(
                                    feature['asset'] as String,
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.contain,
                                  )
                                else if (feature['icon'] != null)
                                  Icon(
                                    feature['icon'] as IconData,
                                    size: iconSize,
                                    color: feature['color'] as Color,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Lens Highlight (Circular)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Text outside the card
          const SizedBox(height: 6),
          Text(
            feature['title'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tealColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFeature(String title) {
    HapticFeedbackHelper.lightImpact();

    // For screens in MainAppShell tabs, switch tabs
    switch (title) {
      case 'Al-Quran':
        mainAppShellKey.currentState?.switchToTab(2);
        return;
      case 'Hadith':
        mainAppShellKey.currentState?.switchToTab(3);
        return;
      case 'Sunnah':
        mainAppShellKey.currentState?.switchToTab(4); // Sunnah tab
        return;
      case 'Tasbih':
        mainAppShellKey.currentState?.switchToTab(5); // Updated from 4 to 5
        return;
    }

    // For screens NOT in MainAppShell tabs, navigate within Shell
    Widget? screen;
    switch (title) {
      case 'Ramadan':
        screen = const RamadanScreen();
        break;
      case 'Dua':
        screen = const DuaScreen();
        break;
      case '99 Names':
        screen = const AllahNamesScreen();
        break;
      case 'Qibla':
        screen = const QiblaFinderScreen();
        break;
      case 'Donate':
        screen = const DonationScreen();
        break;
      case 'Halal Shop':
        screen = const ShopListScreen();
        break;
      case 'Masjid':
        screen = const MasjidListScreen();
        break;
    }

    if (screen != null) {
      // Use Global Navigation (Shell)
      mainAppShellKey.currentState?.openFeature(screen);
    }
  }

  Widget _buildPrayerTimesCard(
    SettingsProvider settings,
    Color tealColor,
    Color goldColor,
    bool isDark,
  ) {
    final service = PrayerTimeService();
    final times = service.getPrayerTimesFormatted(
      latitude: settings.appSettings.prayerLatitude ?? 21.4225,
      longitude: settings.appSettings.prayerLongitude ?? 96.0836,
      asrMethod: settings.appSettings.prayerAsrMethod == 'shafi'
          ? Madhab.shafi
          : Madhab.hanafi,
      method: settings.appSettings.prayerCalculationMethod != null
          ? CalculationMethod.values.firstWhere(
              (m) => m.name == settings.appSettings.prayerCalculationMethod,
              orElse: () => CalculationMethod.other,
            )
          : null,
      use24Hour: false,
    );

    // Get next prayer
    final now = DateTime.now();
    final prayerTimes = service.calculatePrayerTimes(
      date: now,
      latitude: settings.appSettings.prayerLatitude ?? 21.4225,
      longitude: settings.appSettings.prayerLongitude ?? 96.0836,
      asrMethod: settings.appSettings.prayerAsrMethod == 'shafi'
          ? Madhab.shafi
          : Madhab.hanafi,
      method: settings.appSettings.prayerCalculationMethod != null
          ? CalculationMethod.values.firstWhere(
              (m) => m.name == settings.appSettings.prayerCalculationMethod,
              orElse: () => CalculationMethod.other,
            )
          : null,
    );

    String nextPrayer = 'Fajr';
    DateTime? nextPrayerTime;

    if (now.isBefore(prayerTimes.fajr)) {
      nextPrayer = 'Fajr';
      nextPrayerTime = prayerTimes.fajr;
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      nextPrayer = 'Dhuhr';
      nextPrayerTime = prayerTimes.dhuhr;
    } else if (now.isBefore(prayerTimes.asr)) {
      nextPrayer = 'Asr';
      nextPrayerTime = prayerTimes.asr;
    } else if (now.isBefore(prayerTimes.maghrib)) {
      nextPrayer = 'Maghrib';
      nextPrayerTime = prayerTimes.maghrib;
    } else if (now.isBefore(prayerTimes.isha)) {
      nextPrayer = 'Isha';
      nextPrayerTime = prayerTimes.isha;
    } else {
      nextPrayer = 'Fajr';
      nextPrayerTime = prayerTimes.fajr.add(const Duration(days: 1));
    }

    final timeUntilNext = nextPrayerTime.difference(now);
    final hoursLeft = timeUntilNext.inHours;
    final minutesLeft = timeUntilNext.inMinutes % 60;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = 0.4;
        final rawValue = ((_animationController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        final animValue = Curves.easeOutCubic.transform(rawValue);
        return Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (30 * (1 - animValue)) - 12),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedbackHelper.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrayerTimesScreen()),
          );
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.3),
                    ],
              stops: const [0.0, 1.0],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.60),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : tealColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tealColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Image.asset(
                          'assets/icons/icon_masjid.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prayer Times',
                            style: TextStyle(
                              color: tealColor, // Dark Text
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: tealColor.withValues(
                                  alpha: 0.6,
                                ), // Dark Icon
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                settings.appSettings.prayerCity ?? 'Yangon',
                                style: TextStyle(
                                  color: tealColor.withValues(
                                    alpha: 0.7,
                                  ), // Dark Text
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Next Prayer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [goldColor, goldColor.withValues(alpha: 0.8)]
                              : [tealColor, const Color(0xFF1B4D3E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            nextPrayer,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF0D3B2E)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${hoursLeft}h ${minutesLeft}m',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(
                                      0xFF0D3B2E,
                                    ).withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.9),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: tealColor.withValues(alpha: 0.1), // Dark Divider
              ),
              // Prayer Times Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPrayerTime(
                      'Fajr',
                      times['fajr']!,
                      Icons.wb_twilight_rounded,
                      nextPrayer == 'Fajr',
                      tealColor,
                      goldColor,
                    ),
                    _buildPrayerTime(
                      'Dhuhr',
                      times['dhuhr']!,
                      Icons.wb_sunny_rounded,
                      nextPrayer == 'Dhuhr',
                      tealColor,
                      goldColor,
                    ),
                    _buildPrayerTime(
                      'Asr',
                      times['asr']!,
                      Icons.brightness_medium_rounded,
                      nextPrayer == 'Asr',
                      tealColor,
                      goldColor,
                    ),
                    _buildPrayerTime(
                      'Maghrib',
                      times['maghrib']!,
                      Icons.brightness_low_rounded,
                      nextPrayer == 'Maghrib',
                      tealColor,
                      goldColor,
                    ),
                    _buildPrayerTime(
                      'Isha',
                      times['isha']!,
                      Icons.bedtime_rounded,
                      nextPrayer == 'Isha',
                      tealColor,
                      goldColor,
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

  Widget _buildPrayerTime(
    String name,
    String time,
    IconData icon,
    bool isNext,
    Color tealColor,
    Color goldColor,
  ) {
    final timeParts = time.split(' ');
    final timeValue = timeParts[0];
    final period = timeParts.length > 1 ? timeParts[1] : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: isNext
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), // White Highlight
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            )
          : null,
      child: Column(
        children: [
          Icon(
            icon,
            color: isNext
                ? tealColor // Dark Teal
                : tealColor.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            timeValue,
            style: TextStyle(
              color: tealColor, // Always Dark
              fontSize: 13,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            period,
            style: TextStyle(
              color: isNext
                  ? tealColor.withValues(alpha: 0.8)
                  : tealColor.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: isNext ? tealColor : tealColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: isNext ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
