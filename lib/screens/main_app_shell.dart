import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/screens/dashboard_screen.dart';
import 'package:munajat_e_maqbool_app/screens/home_screen.dart';
import 'package:munajat_e_maqbool_app/screens/quran_screen.dart';
import 'package:munajat_e_maqbool_app/screens/hadith_screen.dart';
import 'package:munajat_e_maqbool_app/screens/tasbih_screen.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/sunnah_collection/sunnah_chapters_screen.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/update_service.dart';

// Global key to access MainAppShell state from anywhere
final GlobalKey<MainAppShellState> mainAppShellKey =
    GlobalKey<MainAppShellState>();

class MainAppShell extends StatefulWidget {
  final int initialIndex;

  const MainAppShell({super.key, this.initialIndex = 0});

  @override
  State<MainAppShell> createState() => MainAppShellState();
}

class MainAppShellState extends State<MainAppShell> {
  late int _currentIndex;

  // All available navigation items
  static final List<NavItemData> allNavItems = [
    NavItemData(index: 0, icon: Icons.home_rounded, label: 'Home'),
    NavItemData(
      index: 1,
      icon: Icons.auto_stories_rounded,
      asset: 'assets/icons/icon_dua.png',
      label: 'Munajat',
    ),
    NavItemData(
      index: 2,
      icon: Icons.menu_book_rounded,
      asset: 'assets/icons/icon_quran.png',
      label: 'Quran',
    ),
    NavItemData(
      index: 3,
      icon: Icons.library_books_rounded,
      asset: 'assets/icons/icon_hadith.png',
      label: 'Hadith',
    ),
    NavItemData(
      index: 4,
      icon: Icons.book_rounded,
      asset: 'assets/icons/icon_sunnah.png',
      label: 'Sunnah',
    ),
    NavItemData(
      index: 5,
      icon: Icons.touch_app_rounded,
      asset: 'assets/icons/icon_tasbih.png',
      label: 'Tasbih',
    ),
    NavItemData(index: 6, icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Check for updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context, silent: true);
    });
  }

  // Method to switch to a specific tab from anywhere
  void switchToTab(int index) {
    if (_currentIndex != index && index >= 0 && index < allNavItems.length) {
      HapticFeedbackHelper.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  // Get current tab index
  int get currentIndex => _currentIndex;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const HomeScreen();
      case 2:
        return const QuranScreen();
      case 3:
        return const HadithScreen();
      case 4:
        return const SunnahChaptersScreen();
      case 5:
        return const TasbihScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          allNavItems.length,
          (index) => _buildScreen(index),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildDynamicBottomNavBar(),
    );
  }

  Widget _buildDynamicBottomNavBar() {
    // Get nav items to display (exclude current module if not Home)
    final displayItems = _getDisplayItems();

    // Access SettingsProvider
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.isDarkMode;

    // Theme Colors from GlassTheme
    final tealColor = GlassTheme.text(isDark);
    final goldColor = GlassTheme.accent(isDark);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: GlassTheme.glassGradient(isDark),
          stops: const [0.0, 1.0],
        ),
        border: Border.all(color: GlassTheme.glassBorder(isDark), width: 2.0),
        boxShadow: GlassTheme.glassShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 72,
          color: Colors.transparent, // Transparent to show glass effect
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayItems
                .map((item) => _buildNavItem(item, tealColor, goldColor))
                .toList(),
          ),
        ),
      ),
    );
  }

  List<NavItemData> _getDisplayItems() {
    // If on Home (Dashboard), show all main navigation
    if (_currentIndex == 0) {
      // Show: Home, Munajat, Quran, Hadith, Sunnah (Settings excluded)
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[2], // Quran
        allNavItems[3], // Hadith
        allNavItems[4], // Sunnah
      ];
    }

    // If on Munajat, show other modules
    if (_currentIndex == 1) {
      return [
        allNavItems[0], // Home
        allNavItems[2], // Quran
        allNavItems[3], // Hadith
        allNavItems[4], // Sunnah
        allNavItems[6], // Settings
      ];
    }

    // If on Quran, show other modules
    if (_currentIndex == 2) {
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[3], // Hadith
        allNavItems[4], // Sunnah
        allNavItems[6], // Settings
      ];
    }

    // If on Hadith, show other modules
    if (_currentIndex == 3) {
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[2], // Quran
        allNavItems[4], // Sunnah
        allNavItems[6], // Settings
      ];
    }

    // If on Sunnah, show other modules
    if (_currentIndex == 4) {
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[2], // Quran
        allNavItems[3], // Hadith
        allNavItems[6], // Settings
      ];
    }

    // If on Tasbih, show other modules
    if (_currentIndex == 5) {
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[2], // Quran
        allNavItems[3], // Hadith
        allNavItems[4], // Sunnah
      ];
    }

    // If on Settings, show main modules
    if (_currentIndex == 6) {
      return [
        allNavItems[0], // Home
        allNavItems[1], // Munajat
        allNavItems[2], // Quran
        allNavItems[3], // Hadith
        allNavItems[4], // Sunnah
      ];
    }

    // Default fallback
    return allNavItems.take(5).toList();
  }

  Widget _buildNavItem(NavItemData item, Color tealColor, Color goldColor) {
    final isSelected = _currentIndex == item.index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != item.index) {
          HapticFeedbackHelper.lightImpact();
          setState(() => _currentIndex = item.index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? goldColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: item.asset != null
                  ? Image.asset(
                      item.asset!,
                      width: isSelected ? 26 : 24,
                      height: isSelected ? 26 : 24,
                      opacity: AlwaysStoppedAnimation(isSelected ? 1.0 : 0.6),
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      item.icon,
                      color: isSelected
                          ? goldColor
                          : tealColor.withValues(
                              alpha: 0.6,
                            ), // Dark Teal inactive
                      size: isSelected ? 24 : 22,
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isSelected
                    ? goldColor
                    : tealColor.withValues(alpha: 0.6), // Dark Teal inactive
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItemData {
  final int index;
  final IconData icon;
  final String? asset;
  final String label;

  NavItemData({
    required this.index,
    required this.icon,
    this.asset,
    required this.label,
  });
}
