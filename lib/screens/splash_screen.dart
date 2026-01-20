import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:munajat_e_maqbool_app/services/permission_service.dart';
import 'main_app_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _swayController;
  late AnimationController _flipController; // Added for coin flip

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Initialize flip controller for "coin style" spinning
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Faster, single flip
    )..forward(); // Run once and stop

    _navigateToMainScreen();
  }

  Future<void> _navigateToMainScreen() async {
    // Request permissions while the splash screen is showing
    await PermissionService().requestAllPermissions();

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => onboardingCompleted
              ? MainAppShell(key: mainAppShellKey)
              : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    _flipController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Theme colors matching the website/app
    const tealColor = Color(0xFF0D3B2E);
    const goldColor = Color(0xFFE0B40A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Pattern Overlay (Subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: SvgPicture.asset(
                'assets/splash_screen/pattern-tile.svg',
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // 2. Central Content (Bismillah & Title)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bismillah Graphic with 3D Flip Animation
                AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective perspective
                        ..rotateY(
                          _flipController.value * 2 * math.pi,
                        ), // 360 degree spin
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 3),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(30),
                    child: SvgPicture.asset(
                      'assets/splash_screen/bismillah.svg',
                      // Showing original SVG colors
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App Name
                Text(
                  'Myanmar Muslim Oasis',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: tealColor,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'SEEKING KNOWLEDGE', // Tagline from website image
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: goldColor,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ),

          // 3. Hanging Elements (Animated)
          // Lanterns hanging from top right
          Positioned(
            top: -20, // Start slightly above
            right: size.width * 0.1,
            child: _HangingItem(
              controller: _swayController,
              assetPath: 'assets/splash_screen/lantern.svg',
              height: 180,
              swayAngle: 0.05,
              delay: 0.0,
              // No solid color override for lantern
            ),
          ),
          Positioned(
            top: -10,
            right: size.width * 0.25,
            child: _HangingItem(
              controller: _swayController,
              assetPath: 'assets/splash_screen/moon.svg',
              height: 120,
              swayAngle: 0.08,
              delay: 0.5,
              color: goldColor,
            ),
          ),
          Positioned(
            top: -5,
            right: size.width * 0.05,
            child: _HangingItem(
              controller: _swayController,
              assetPath: 'assets/splash_screen/Star.svg',
              height: 100,
              swayAngle: 0.06,
              delay: 1.0,
              color: goldColor,
            ),
          ),

          // 5. Developer Name (Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Developed By',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SayarHtoo (Kaytumati)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tealColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HangingItem extends StatelessWidget {
  final AnimationController controller;
  final String assetPath;
  final double height;
  final double swayAngle;
  final double delay;
  final Color? color;

  const _HangingItem({
    required this.controller,
    required this.assetPath,
    required this.height,
    required this.swayAngle,
    this.delay = 0.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate sway using sine wave for pendulum effect
        // Adding delay phase shift
        final double value = math.sin((controller.value * 2 * math.pi) + delay);
        final double angle = value * swayAngle;

        return Transform(
          transform: Matrix4.rotationZ(angle),
          alignment: Alignment.topCenter, // Pivot at text/string attachment
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The string/line holding the item
              Container(
                width: 2,
                height: height * 0.3, // Top 30% is string
                color: const Color(0xFFE0B40A),
              ),
              // The SVG Item
              SvgPicture.asset(
                assetPath,
                height: height * 0.7,
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
