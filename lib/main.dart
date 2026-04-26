import 'package:candlestick_master/core/router/app_router.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/services/fcm_service.dart';
import 'package:candlestick_master/core/services/local_notification_service.dart';
import 'package:candlestick_master/core/services/meta_analytics_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/data/repositories/pattern_repository.dart';
import 'package:candlestick_master/firebase_options.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:candlestick_master/providers/quiz_notifier.dart';
import 'package:candlestick_master/providers/theme_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =============================================================================
// Main Entry Point
// =============================================================================
// Initialize all services before running the app:
// 1. Firebase (required for FCM, Firestore, Auth)
// 2. AdService (Google AdMob for monetization)
// 3. FCMService (Push notifications for engagement)
// 4. ThemeNotifier & UserProgressNotifier (load persisted preferences)
// =============================================================================

void main() async {
  // Ensure Flutter bindings are initialized (required for async operations before runApp)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AdMob SDK for monetization
  // TODO: Replace test ad IDs with production IDs before release
  await AdService.instance.initialize();
  await AdService.instance.startSession();

  // Initialize Meta (Facebook) SDK — app install tracking & ads attribution
  // NOTE: Ensure facebook_app_id and facebook_client_token are set in
  //       android/app/src/main/res/values/strings.xml before running.
  await MetaAnalyticsService.instance.initialize();

  // Log the app open event so Meta Ads can track daily active usage
  await MetaAnalyticsService.instance.logAppOpen();

  // Initialize Firebase Cloud Messaging for push notifications
  FCMService.onNotificationTap = (data) {
    final route = data['route'];
    if (route is String && route.isNotEmpty) {
      appRouter.go(route);
      return;
    }

    final patternId = data['patternId'];
    if (patternId is String && patternId.isNotEmpty) {
      appRouter.go('/pattern/$patternId');
    }
  };
  await FCMService().initialize();

  // Initialize Local Notifications
  await LocalNotificationService().initialize();
  await LocalNotificationService().scheduleAllDailyReminders();

  // Create and initialize providers that need async initialization
  final themeNotifier = ThemeNotifier();
  final userProgressNotifier = UserProgressNotifier();
  final gamificationNotifier = GamificationNotifier();

  // Load persisted preferences before app starts
  await Future.wait([
    themeNotifier.initialize(),
    userProgressNotifier.initialize(),
    gamificationNotifier.initialize(),
  ]);

  runApp(MyApp(
    themeNotifier: themeNotifier,
    userProgressNotifier: userProgressNotifier,
    gamificationNotifier: gamificationNotifier,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final UserProgressNotifier userProgressNotifier;
  final GamificationNotifier gamificationNotifier;

  const MyApp({
    super.key,
    required this.themeNotifier,
    required this.userProgressNotifier,
    required this.gamificationNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => PatternsNotifier(PatternRepository())),
        ChangeNotifierProvider(create: (_) => QuizNotifier()),
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: userProgressNotifier),
        ChangeNotifierProvider.value(value: gamificationNotifier),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Candlestick Master',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
