import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart';
import 'package:munajat_e_maqbool_app/screens/display_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/language_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/screens/notification_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/prayer_times_screen.dart';
import 'package:munajat_e_maqbool_app/screens/widget_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/onboarding_screen.dart';
import 'package:munajat_e_maqbool_app/screens/main_app_shell.dart';
import 'package:munajat_e_maqbool_app/screens/admin/admin_login_screen.dart';
import 'package:munajat_e_maqbool_app/screens/auth/login_screen.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import '../utils/haptic_feedback_helper.dart';
import '../utils/animation_helpers.dart';
import '../providers/settings_provider.dart';
import '../services/update_service.dart';
import '../screens/halal_shop/shop_list_screen.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _settingsItems = [
    {
      'icon': Icons.palette_outlined,
      'title': 'Display & Theme',
      'subtitle': 'Customize appearance and colors',
      'color': const Color(0xFF9C27B0),
      'screen': const DisplaySettingsScreen(),
    },
    {
      'icon': Icons.storefront_outlined,
      'title': 'Halal Shops',
      'subtitle': 'Find nearby Halal shops',
      'color': const Color(0xFF4CAF50),
      'screen': const ShopListScreen(),
    },
    {
      'icon': Icons.system_update_outlined,
      'title': 'Check for Updates',
      'subtitle': 'Check for new version',
      'color': const Color(0xFF607D8B),
      'screen': null, // Action item
    },
    {
      'icon': Icons.language_outlined,
      'title': 'Language',
      'subtitle': 'Change translation language',
      'color': const Color(0xFF2196F3),
      'screen': const LanguageSettingsScreen(),
    },
    {
      'icon': Icons.favorite_outline,
      'title': 'Dua Preferences',
      'subtitle': 'Audio and reading settings',
      'color': const Color(0xFFE91E63),
      'screen': const DuaPreferencesScreen(),
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Reminders',
      'subtitle': 'Daily prayer notifications',
      'color': const Color(0xFFFF9800),
      'screen': const NotificationSettingsScreen(),
    },
    {
      'icon': Icons.access_time_outlined,
      'title': 'Prayer Times',
      'subtitle': 'View and configure prayer times',
      'color': const Color(0xFF4CAF50),
      'screen': const PrayerTimesScreen(),
    },
    {
      'icon': Icons.collections_bookmark_outlined,
      'title': 'Collections',
      'subtitle': 'Manage custom dua collections',
      'color': const Color(0xFF00BCD4),
      'screen': const CustomCollectionsScreen(),
    },
    {
      'icon': Icons.widgets_outlined,
      'title': 'Widgets',
      'subtitle': 'Lock screen and home screen widgets',
      'color': const Color(0xFF795548),
      'screen': const WidgetSettingsScreen(),
    },
  ];

  int _versionTapCount = 0;
  DateTime? _lastVersionTap;
  String _version = '';

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Switch to Dashboard (Tab 0) when back is pressed
            mainAppShellKey.currentState?.switchToTab(0);
          },
          child: GlassScaffold(
            title: 'Settings',
            automaticallyImplyLeading: false, // Prevents default back button
            // Add custom leading button to go back to Dashboard
            leading: GestureDetector(
              onTap: () {
                HapticFeedbackHelper.lightImpact();
                mainAppShellKey.currentState?.switchToTab(0);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 100,
              ),
              itemCount:
                  _settingsItems.length + 2, // +1 for Account, +1 for Tutorial
              itemBuilder: (context, index) {
                // Account section comes first
                if (index == 0) {
                  return _buildAccountSection(isDark, textColor, accentColor);
                }

                // Then settings items (adjusted index)
                final adjustedIndex = index - 1;
                if (adjustedIndex < _settingsItems.length) {
                  final item = _settingsItems[adjustedIndex];
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = (adjustedIndex * 0.08).clamp(0.0, 0.5);
                      final rawValue = (_animationController.value - delay)
                          .clamp(0.0, 1.0);
                      final animValue = Curves.easeOutCubic.transform(rawValue);
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - animValue)),
                        child: Opacity(
                          opacity: animValue.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildSettingsItem(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      color: item['color'] as Color,
                      isDark: isDark,
                      textColor: textColor,
                      onTap: () {
                        if (item['screen'] != null) {
                          _navigateToScreen(context, item['screen'] as Widget);
                        } else if (item['title'] == 'Check for Updates') {
                          UpdateService().checkForUpdates(context);
                        }
                      },
                    ),
                  );
                }

                // Tutorial section at the end
                return _buildTutorialSection(isDark, textColor, accentColor);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(bool isDark, Color textColor, Color accentColor) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final isLoggedIn = currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        GlassCard(
          isDark: isDark,
          borderRadius: 16,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoggedIn
                ? Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.15),
                              accentColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Icon(Icons.person, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.email ?? 'User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Logged in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await authService.signOut();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      HapticFeedbackHelper.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withValues(alpha: 0.15),
                                accentColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Icon(
                            Icons.login_outlined,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login / Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sign in to access shop features',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        onTap: () {
          HapticFeedbackHelper.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialSection(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        textColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Help',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        textColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          isDark: isDark,
          borderRadius: 16,
          padding: EdgeInsets.zero,
          onTap: () => _resetOnboarding(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Tutorial',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'See app introduction again',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _handleVersionTap(context),
          child: Text(
            'Munajat-e-Maqbool $_version',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Made with ❤️ for Muslims',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.3),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleVersionTap(BuildContext context) {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_lastVersionTap == null ||
        now.difference(_lastVersionTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 1;
    } else {
      _versionTapCount++;
    }
    _lastVersionTap = now;

    // Show remaining taps hint after 3 taps
    if (_versionTapCount >= 3 && _versionTapCount < 7) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${7 - _versionTapCount} more taps...'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }

    // Open admin login after 7 taps
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, AnimationHelpers.slideTransition(screen));
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }
}
