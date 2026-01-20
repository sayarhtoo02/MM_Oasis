import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/quran_provider.dart';
import 'package:munajat_e_maqbool_app/providers/hadith_provider.dart';
import 'package:munajat_e_maqbool_app/providers/ramadan_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_list_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/display_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/language_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart'; // Import CustomCollectionsScreen
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/screens/splash_screen.dart'; // Import the splash screen
import 'package:munajat_e_maqbool_app/screens/onboarding_screen.dart'; // Import onboarding screen
import 'package:munajat_e_maqbool_app/config/app_theme.dart';
import 'package:munajat_e_maqbool_app/config/app_constants.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collection_detail_screen.dart'; // Import CustomCollectionDetailScreen
import 'package:munajat_e_maqbool_app/models/custom_collection.dart'; // Import CustomCollection
import 'package:munajat_e_maqbool_app/services/settings_repository.dart'; // New import
import 'package:munajat_e_maqbool_app/services/notification_service.dart'; // Import notification service
import 'package:munajat_e_maqbool_app/services/widget_service.dart'; // Import widget service
import 'package:munajat_e_maqbool_app/screens/munajat_main_screen.dart'; // Import MunajatMainScreen
import 'package:munajat_e_maqbool_app/screens/main_app_shell.dart'; // Import MainAppShell
import 'package:munajat_e_maqbool_app/screens/bookmarks_screen.dart'; // Import BookmarksScreen
import 'package:munajat_e_maqbool_app/screens/search_screen.dart'; // Import SearchScreen
import 'package:munajat_e_maqbool_app/screens/widget_settings_screen.dart'; // Import WidgetSettingsScreen
import 'package:munajat_e_maqbool_app/services/shop_notification_service.dart';
import 'package:munajat_e_maqbool_app/services/background_service_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import notifications

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action when app is in background
  debugPrint('notificationTapBackground: ${notificationResponse.payload}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lgmbvrtkulhwylmwhoou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWJ2cnRrdWxod3lsbXdob291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MDc5NTIsImV4cCI6MjA4MzI4Mzk1Mn0.MUl09e5NufjdyO0J0kP1u9BETBTQuNOMgvAXXuEsx_o',
  );

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      ); // Use standard launcher icon
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
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
          // Handle notification tap when app is in foreground
          debugPrint(
            'onDidReceiveNotificationResponse: ${notificationResponse.payload}',
          );
        },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Request permissions for Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  final duaProvider = DuaProvider();
  await duaProvider.loadAllDuas();

  // Initialize notification service
  final notificationService = NotificationService(
    flutterLocalNotificationsPlugin,
  );

  // Register Shop Notification Service Global Instance
  final shopNotificationService = ShopNotificationService(
    notificationService,
    navigatorKey,
  );

  // Initialize widget service
  await WidgetService.initialize();

  // Create notification channel BEFORE starting foreground service (required for Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'shop_orders', // Must match the channel ID in BackgroundServiceManager
    'Shop Order Notifications',
    description: 'Notifications for shop order monitoring',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Initialize Background Service (Foreground Service for notifications)
  await BackgroundServiceManager.initializeService();
  // Request Battery Unrestricted status
  await BackgroundServiceManager.requestUnrestrictedBattery();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              SettingsProvider(SettingsRepository(), notificationService),
        ),
        ChangeNotifierProvider(create: (_) => duaProvider),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => HadithProvider()),
        ChangeNotifierProvider(create: (_) => RamadanProvider()),
        ChangeNotifierProvider.value(
          value: shopNotificationService,
        ), // Inject Global ShopNotificationService
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
          navigatorKey: navigatorKey, // Use global navigator key
          title: 'Munajat-e-Maqbool App',
          theme: AppTheme.lightTheme(
            context,
            settingsProvider.appSettings.accentColor,
          ),
          darkTheme: AppTheme.darkTheme(
            context,
            settingsProvider.appSettings.accentColor,
          ), // Add dark theme
          themeMode:
              settingsProvider.appSettings.themeMode == AppThemeMode.system
              ? ThemeMode.system
              : (settingsProvider.appSettings.themeMode == AppThemeMode.light
                    ? ThemeMode.light
                    : ThemeMode.dark),
          home: const SplashScreen(), // Set SplashScreen as the initial screen
          routes: {
            '/onboarding': (context) =>
                const OnboardingScreen(), // Onboarding route
            '/main': (context) =>
                MainAppShell(key: mainAppShellKey), // Main app with bottom nav
            '/munajat_main': (context) =>
                const MunajatMainScreen(), // New Munajat module root
            '/dua_list': (context) => const DuaListScreen(),
            '/dua_detail': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return DuaDetailScreen(
                initialDua: args['selectedDua'],
                manzilDuas: args['manzilDuas'],
              );
            },
            '/settings': (context) => const SettingsScreen(),
            '/display_settings': (context) => const DisplaySettingsScreen(),
            '/language_settings': (context) => const LanguageSettingsScreen(),
            '/dua_preferences': (context) => const DuaPreferencesScreen(),
            '/bookmarks': (context) =>
                const BookmarksScreen(), // New BookmarksScreen route
            '/search': (context) =>
                const SearchScreen(), // New SearchScreen route
            '/custom-collections': (context) => const CustomCollectionsScreen(),
            '/widget-settings': (context) => const WidgetSettingsScreen(),
            AppConstants.customCollectionDetailRoute: (context) {
              final collection =
                  ModalRoute.of(context)!.settings.arguments
                      as CustomCollection;
              return CustomCollectionDetailScreen(collection: collection);
            },
          },
        );
      },
    );
  }
}
