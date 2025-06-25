import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_list_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/display_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/language_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/screens/splash_screen.dart'; // Import the splash screen
import 'package:munajat_e_maqbool_app/config/app_theme.dart';
import 'package:munajat_e_maqbool_app/services/settings_repository.dart'; // New import
import 'package:munajat_e_maqbool_app/screens/main_screen.dart'; // Import MainScreen
import 'package:munajat_e_maqbool_app/screens/home_screen.dart'; // Import HomeScreen
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen.dart'; // Import BookmarksScreen
import 'package:munajat_e_maqbool_app/screens/search_screen.dart'; // Import SearchScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final duaProvider = DuaProvider();
  await duaProvider.loadAllDuas();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(SettingsRepository())), // Updated
        ChangeNotifierProvider(create: (_) => duaProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: 'Munajat-e-Maqbool App',
          theme: AppTheme.lightTheme(context),
          darkTheme: AppTheme.darkTheme(context), // Add dark theme
          themeMode: settingsProvider.appSettings.displaySettings.selectedThemeMode, // Updated
          home: const SplashScreen(), // Set SplashScreen as the initial screen
          routes: {
            '/main': (context) => const MainScreen(), // New MainScreen route
            '/home': (context) => const HomeScreen(), // Add HomeScreen route
            '/dua_list': (context) => const DuaListScreen(),
            '/dua_detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return DuaDetailScreen(
                initialDua: args['selectedDua'],
                manzilDuas: args['manzilDuas'],
              );
            },
            '/settings': (context) => const SettingsScreen(),
            '/display_settings': (context) => const DisplaySettingsScreen(),
            '/language_settings': (context) => const LanguageSettingsScreen(),
            '/dua_preferences': (context) => const DuaPreferencesScreen(),
            '/bookmarks': (context) => const BookmarksScreen(), // New BookmarksScreen route
            '/search': (context) => const SearchScreen(), // New SearchScreen route
          },
        );
      },
    );
  }
}
