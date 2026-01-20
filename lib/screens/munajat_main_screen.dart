import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/screens/home_screen.dart';
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import '../config/glass_theme.dart';

class MunajatMainScreen extends StatefulWidget {
  const MunajatMainScreen({super.key});

  @override
  State<MunajatMainScreen> createState() => _MunajatMainScreenState();
}

class _MunajatMainScreenState extends State<MunajatMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarksScreen(),
    const DuaPreferencesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return Scaffold(
          body: Stack(
            children: [
              // Background
              Container(color: GlassTheme.background(isDark)),
              _screens[_currentIndex],
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildAnimatedBottomNav(isDark, textColor, accentColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBottomNav(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: GlassTheme.glassGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: GlassTheme.glassBorder(isDark), width: 2),
        boxShadow: GlassTheme.glassShadow(isDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            0,
            Icons.menu_book_rounded,
            'Home',
            isDark,
            textColor,
            accentColor,
          ),
          _buildNavItem(
            1,
            Icons.bookmark_rounded,
            'Bookmarks',
            isDark,
            textColor,
            accentColor,
          ),
          _buildNavItem(
            2,
            Icons.settings_rounded,
            'Settings',
            isDark,
            textColor,
            accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedbackHelper.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : textColor.withValues(alpha: 0.5),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
