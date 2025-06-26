import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:munajat_e_maqbool_app/screens/main_screen.dart'; // Import MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainScreen();
  }

  Future<void> _navigateToMainScreen() async {
    await Future.delayed(const Duration(milliseconds: 4000), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Or your desired background color
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2), // Low opacity
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'မောင်လာနာ အရှ်ရဖ်အလီ(ထာနဝီ) ၏',
                    textStyle: const TextStyle(
                      fontFamily: 'Myanmar',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 6, 0, 88),
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 3, // Repeat multiple times
                pause: const Duration(milliseconds: 2000), // Increased pause duration
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/banner green.png',
                    width: 350, // Increased width
                    height: 200, // Adjusted height
                  ),
                  Text(
                    'မုနာဂျာသေ မက်ဗူးလ်ကျမ်း',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Myanmar',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Changed to white
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Develop By ဆရာထူး (ကေတုမတီ)',
                    textStyle: const TextStyle(
                      fontFamily: 'Myanmar',
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 0, 0, 0), // Changed to black
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 3, // Repeat multiple times to ensure all text is seen
                pause: const Duration(milliseconds: 2000), // Increased pause duration
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
