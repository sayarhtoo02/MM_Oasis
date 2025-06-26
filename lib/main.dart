import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_list_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/display_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/language_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart'; // Import CustomCollectionsScreen
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/screens/splash_screen.dart'; // Import the splash screen
import 'package:munajat_e_maqbool_app/config/app_theme.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart'; // Import CustomCollectionDetailScreen
import 'package:munajat_e_maqbool_app/models/custom_collection.dart'; // Import CustomCollection
import 'package:munajat_e_maqbool_app/services/settings_repository.dart'; // New import
import 'package:munajat_e_maqbool_app/screens/main_screen.dart'; // Import MainScreen
import 'package:munajat_e_maqbool_app/screens/home_screen.dart'; // Import HomeScreen
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen.dart'; // Import BookmarksScreen
import 'package:munajat_e_maqbool_app/screens/search_screen.dart'; // Import SearchScreen
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import notifications

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action when app is in background
  debugPrint('notificationTapBackground: ${notificationResponse.payload}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher'); // Use standard launcher icon
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      // Handle notification tap when app is in foreground
      debugPrint('onDidReceiveNotificationResponse: ${notificationResponse.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Request permissions for Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

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
          theme: AppTheme.lightTheme(context, settingsProvider.appSettings.accentColor),
          darkTheme: AppTheme.darkTheme(context, settingsProvider.appSettings.accentColor), // Add dark theme
          themeMode: settingsProvider.appSettings.themeMode == AppThemeMode.system
              ? ThemeMode.system
              : (settingsProvider.appSettings.themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark),
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
            '/custom-collections': (context) => const CustomCollectionsScreen(),
            AppConstants.customCollectionDetailRoute: (context) {
              final collection = ModalRoute.of(context)!.settings.arguments as CustomCollection;
              return CustomCollectionDetailScreen(collection: collection);
            },
          },
        );
      },
    );
  }
}
