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

  // Initialize with safe fallbacks for all devices
  DuaProvider? duaProvider;
  NotificationService? notificationService;
  ShopNotificationService? shopNotificationService;

  try {
    // 1. Critical Initialization (Must run first)
    await Supabase.initialize(
      url: 'https://lgmbvrtkulhwylmwhoou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWJ2cnRrdWxod3lsbXdob291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MDc5NTIsImV4cCI6MjA4MzI4Mzk1Mn0.MUl09e5NufjdyO0J0kP1u9BETBTQuNOMgvAXXuEsx_o',
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Initialize sqflite for desktop platforms
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  } catch (e) {
    debugPrint('Desktop DB init error: $e');
  }

  // 2. Initialize Providers & Services (with fallbacks)
  duaProvider = DuaProvider();
  notificationService = NotificationService(flutterLocalNotificationsPlugin);
  shopNotificationService = ShopNotificationService(
    notificationService,
    navigatorKey,
  );

  // 3. Parallel Initialization of Independent Async Tasks (with error handling)
  try {
    await Future.wait([
      // A. Load All Duas (Heavy JSON)
      duaProvider.loadAllDuas().catchError((e) {
        debugPrint('Dua loading error: $e');
      }),

      // B. Initialize Widget Service (SharedPreferences)
      WidgetService.initialize().catchError((e) {
        debugPrint('Widget service init error: $e');
      }),

      // C. Initialize Notifications Plugin
      _initNotifications().catchError((e) {
        debugPrint('Notifications init error: $e');
      }),

      // D. Initialize Background Service (can fail on some devices)
      BackgroundServiceManager.initializeService().catchError((e) {
        debugPrint('Background service init error: $e');
      }),
    ]);
  } catch (e) {
    debugPrint('Parallel init error: $e');
  }

  // 4. Post-Init Setup (Sequential requirements) - All wrapped in try-catch
  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  } catch (e) {
    debugPrint('Notification permission error: $e');
  }

  try {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shop_orders',
      'Shop Order Notifications',
      description: 'Notifications for shop order monitoring',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // NOW start the background service after channel is ready
    await BackgroundServiceManager.startService();
  } catch (e) {
    debugPrint('Notification channel error: $e');
  }

  try {
    await BackgroundServiceManager.requestUnrestrictedBattery();
  } catch (e) {
    debugPrint('Battery optimization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              SettingsProvider(SettingsRepository(), notificationService!),
        ),
        ChangeNotifierProvider(create: (_) => duaProvider!),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => HadithProvider()),
        ChangeNotifierProvider(create: (_) => RamadanProvider()),
        ChangeNotifierProvider.value(value: shopNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
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
          debugPrint(
            'onDidReceiveNotificationResponse: ${notificationResponse.payload}',
          );
        },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
