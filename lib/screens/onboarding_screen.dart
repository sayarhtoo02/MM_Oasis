import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import 'package:munajat_e_maqbool_app/services/permission_service.dart';
import '../config/glass_theme.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to\nMyanmar Muslim Oasis',
      burmeseTitle: 'မြန်မာမွတ်စ်လင်မ် အိုအေစစ် မှ\nကြိုဆိုပါ၏',
      description:
          'Your complete Islamic companion for daily prayers, spiritual growth, and connection with Allah.',
      burmeseDescription:
          'နေ့စဉ် ဝတ်ပြုမှုနှင့် အလ္လာဟ်အရှင်မြတ်နှင့် ရင်းနှီးမှု တိုးပွားစေရန် အကောင်းဆုံး အဖော်မွန်။',
      iconAsset: 'assets/images/app_icon.png',
    ),
    OnboardingPage(
      title: 'Daily Conversational\nMunajat',
      burmeseTitle:
          'မောင်လာနာ အရှ်ရဖ်အလီ (ထာနဝီ) သခင်ပြုစုသည့်\nမုနာဂျာသေ မက်ဘူးလ်ကျမ်း',
      description:
          'Read the 7 Manzils organized by weekdays. Track your progress seamlessly and build a consistent habit.',
      burmeseDescription:
          'နေ့ရက်အလိုက် သတ်မှတ်ထားသော မုနာဂျသ် ၇-စောင်ကို ဖတ်ရှုပြီး တသမတ်တည်း အလေ့အကျင့်ကောင်းများ တည်ဆောက်ပါ။',
      iconAsset: 'assets/icons/icon_dua.png',
    ),
    OnboardingPage(
      title: 'Quran, Hadith\n& Sunnah',
      burmeseTitle: 'ကုရ်အာန်၊ ဟဒီးဆ် နှင့်\nစွန္နသ်တော်များ',
      description:
          'Access the Holy Quran, authentic Hadith collections, and Sunnahs with translations in multiple languages.',
      burmeseDescription:
          'ကုရ်အာန်၊ ဟဒီးဆ် နှင့် စွန္နသ်တော်များကို မြန်မာဘာသာစကား ဖြင့် လေ့လာဖတ်ရှုနိုင်ပါသည်။',
      iconAsset: 'assets/icons/icon_quran.png',
    ),
    OnboardingPage(
      title: 'Powerful\nIslamic Tools',
      burmeseTitle: 'မွတ်စ်လင်များအတွက် \nအသုံးဝင်သော အခြားလုပ်ဆောင်ချက်များ',
      description:
          'Accurate Prayer Times, Qibla Finder, Tasbih Counter, and 99 Names of Allah - all in one place.',
      burmeseDescription:
          'တိကျသော ဝတ်ပြုချိန်များ၊ ကစ်ဗ်လာ ရှာဖွေစက်၊ သစ်စ်ဗီ ရေတွက်စက် နှင့် အလ္လာဟ်အရှင်မြတ်၏ နာမတော် ၉၉-ပါး တို့ကို တစ်နေရာတည်းတွင် ရရှိနိုင်ပါသည်။',
      iconAsset:
          'assets/icons/icon_qibla.png', // Using donation icon as a placeholder/generic positive icon if settings icon absent, or maybe just re-use one. But user asked for THESE icons. Let's use donation or maybe generic. Re-using icon_quran might be confusing. Let's use icon_donation.png as it looks distinct, or maybe just icon_99_names. Let's use icon_99_names for personalization/spiritual identity.
      isPersonalization: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final accentColor = GlassTheme.accent(isDark);
        final textColor = GlassTheme.text(isDark);
        final currentLang =
            settingsProvider.appSettings.languageSettings.selectedLanguage;
        // Check if language is Burmese (assuming 'mm' or 'my' code)
        final isBurmese = currentLang == 'mm' || currentLang == 'my';

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // 1. Dynamic Background Gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getGradientColors(_currentPage, isDark),
                  ),
                ),
              ),

              // 2. Pattern Overlay
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/pattern_islamic.png'),
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
              ),

              // 3. Blur Effect (Glassmorphism base)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: Language Toggle & Skip
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Language Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTopLanguageOption(
                                  label: 'ENG',
                                  isSelected: !isBurmese,
                                  onTap: () => settingsProvider
                                      .setSelectedLanguage('en'),
                                  isDark: isDark,
                                  accentColor: accentColor,
                                ),
                                _buildTopLanguageOption(
                                  label: 'MM',
                                  isSelected: isBurmese,
                                  onTap: () => settingsProvider
                                      .setSelectedLanguage('mm'),
                                  isDark: isDark,
                                  accentColor: accentColor,
                                ),
                              ],
                            ),
                          ),

                          // Skip Button
                          _currentPage < _pages.length - 1
                              ? TextButton(
                                  onPressed: () {
                                    HapticFeedbackHelper.lightImpact();
                                    _completeOnboarding();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: textColor,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontFamily: 'Myanmar',
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  width: 48,
                                ), // Placeholder to balance if needed, or just shrink
                        ],
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          HapticFeedbackHelper.selectionClick();
                          setState(() => _currentPage = index);
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) => _buildPageContent(
                          _pages[index],
                          accentColor,
                          textColor,
                          isDark,
                          isBurmese,
                        ),
                      ),
                    ),

                    // Bottom Navigation Area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Column(
                        children: [
                          // Page Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (index) => _buildDot(index, accentColor),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Action Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _currentPage == _pages.length - 1
                                  ? _completeOnboarding
                                  : () {
                                      HapticFeedbackHelper.lightImpact();
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: isDark
                                    ? Colors.black
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _currentPage == _pages.length - 1
                                    ? (isBurmese ? 'စတင်ပါ' : 'Get Started')
                                    : (isBurmese ? 'ဆက်သွားပါ' : 'Continue'),
                                style: const TextStyle(
                                  fontFamily: 'Myanmar',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Myanmar',
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(
    OnboardingPage page,
    Color accentColor,
    Color textColor,
    bool isDark,
    bool isBurmese,
  ) {
    return SingleChildScrollView(
      // Added scroll view for safety on smaller screens
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icon/Image Container with Glassmorphism
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    page.iconAsset,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Titles
          Text(
            isBurmese ? page.burmeseTitle : page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Myanmar',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 24),

          // Descriptions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              isBurmese ? page.burmeseDescription : page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Myanmar',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),
          // Personalization Page Extra Content (if needed, simplified now)
          if (page.isPersonalization) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color accentColor) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? accentColor : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  List<Color> _getGradientColors(int index, bool isDark) {
    if (isDark) {
      // Darker, richer gradients for dark mode
      switch (index) {
        case 0: // Welcome (Dua)
          return [
            const Color(0xFF0F2027),
            const Color(0xFF203A43),
            const Color(0xFF2C5364),
          ];
        case 1: // Munajat (Quran)
          return [const Color(0xFF141E30), const Color(0xFF243B55)];
        case 2: // Quran/Hadith
          return [const Color(0xFF000000), const Color(0xFF434343)];
        case 3: // Tools (Tasbih)
          return [const Color(0xFF232526), const Color(0xFF414345)];
        case 4: // Personalize
          return [const Color(0xFF16222A), const Color(0xFF3A6073)];
        default:
          return [const Color(0xFF0F2027), const Color(0xFF2C5364)];
      }
    }
    // Lighter, fresher gradients for light mode
    switch (index) {
      case 0: // Welcome
        return [const Color(0xFF134E5E), const Color(0xFF71B280)]; // Teal/Green
      case 1: // Munajat
        return [
          const Color(0xFFCC95C0),
          const Color(0xFFDBD4B4),
          const Color(0xFF7AA1D2),
        ]; // Pastel Mix
      case 2: // Quran/Hadith
        return [const Color(0xFF2193b0), const Color(0xFF6dd5ed)]; // Blue
      case 3: // Tools
        return [const Color(0xFF56ab2f), const Color(0xFFa8e063)]; // Green
      case 4: // Personalize
        return [
          const Color(0xFF4568DC),
          const Color(0xFFB06AB3),
        ]; // Purple/Blue
      default:
        return [const Color(0xFF134E5E), const Color(0xFF71B280)];
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedbackHelper.success();
    // Request permissions before completing onboarding
    await PermissionService().requestAllPermissions();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String burmeseTitle;
  final String description;
  final String burmeseDescription;
  final String iconAsset;
  final bool isPersonalization;

  OnboardingPage({
    required this.title,
    required this.burmeseTitle,
    required this.description,
    required this.burmeseDescription,
    required this.iconAsset,
    this.isPersonalization = false,
  });
}
