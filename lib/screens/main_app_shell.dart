import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/screens/dashboard_screen.dart';
import 'package:munajat_e_maqbool_app/screens/home_screen.dart';
import 'package:munajat_e_maqbool_app/screens/quran_screen.dart';
import 'package:munajat_e_maqbool_app/screens/hadith_screen.dart';
import 'package:munajat_e_maqbool_app/screens/tasbih_screen.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/sunnah_collection/sunnah_chapters_screen.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import 'package:munajat_e_maqbool_app/services/update_service.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';

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
  Widget? _currentFeatureScreen; // Track current feature screen

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
    HapticFeedbackHelper.lightImpact();
    setState(() {
      _currentIndex = index;
      _currentFeatureScreen = null; // Always clear feature screen
    });
  }

  // Open a feature screen within the shell (keeping bottom nav)
  void openFeature(Widget screen) {
    setState(() {
      _currentFeatureScreen = screen;
    });
  }

  // Close the current feature screen
  void closeFeature() {
    setState(() {
      _currentFeatureScreen = null;
    });
  }

  // Get current tab index
  int get currentIndex => _currentIndex;

  Future<bool> _onWillPop() async {
    if (_currentFeatureScreen != null) {
      closeFeature();
      return false;
    }
    if (_currentIndex != 0) {
      switchToTab(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFFFD700);
    final tealColor = const Color(0xFF004D40);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true, // Important for glass effect
        backgroundColor:
            Colors.transparent, // Let background show through if any
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/background.jpg',
              ), // Assuming a standard BG
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Main Content (IndexedStack for persistence)
                IndexedStack(
                  index: _currentIndex,
                  children: [
                    const DashboardScreen(),
                    const HomeScreen(),
                    const QuranScreen(),
                    const HadithScreen(),
                    const SunnahChaptersScreen(),
                    const TasbihScreen(),
                    const SettingsScreen(),
                  ],
                ),

                // Feature Screen Overlay
                if (_currentFeatureScreen != null)
                  Positioned.fill(child: _currentFeatureScreen!),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildDynamicBottomNavBar(tealColor, goldColor),
      ),
    );
  }

  Widget _buildDynamicBottomNavBar(Color tealColor, Color goldColor) {
    final displayItems = _getDisplayItems();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassCard(
        borderRadius: 25,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: displayItems
              .map((item) => _buildNavItem(item, tealColor, goldColor))
              .toList(),
        ),
      ),
    );
  }

  List<NavItemData> _getDisplayItems() {
    // Logic to show 5 items max, swapping center or others based on selection
    // Basic implementation: Always show Home (0), Munajat(1), Quran(2)...
    // Or dynamic sliding window.
    // Let's implement a fixed set plus the selected one if strictly needed,
    // or just the full list if it fits? 7 items might be too tight.
    // Let's prioritize: Home(0), [Selected/Relevant], Settings(6)

    // Standard set: Home, Munajat, Quran, Hadith, Settings
    List<int> visibleIndices = [0, 1, 2, 3, 6];

    if (_currentIndex == 4) {
      // Sunnah selected
      visibleIndices = [0, 1, 4, 3, 6]; // Swap middle?
    } else if (_currentIndex == 5) {
      // Tasbih
      visibleIndices = [0, 5, 2, 3, 6];
    }

    return allNavItems
        .where((item) => visibleIndices.contains(item.index))
        .toList();
  }

  Widget _buildNavItem(NavItemData item, Color tealColor, Color goldColor) {
    final isSelected = _currentIndex == item.index;

    return GestureDetector(
      onTap: () => switchToTab(item.index), // Use unified method
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
