import "dart:async";
import "package:candlestick_master/core/router/app_router.dart";
import "package:candlestick_master/core/services/ad_service.dart";
import "package:candlestick_master/core/services/fcm_service.dart";
import "package:candlestick_master/core/services/local_notification_service.dart";
import "package:candlestick_master/core/services/meta_analytics_service.dart";
import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/data/repositories/pattern_repository.dart";
import "package:candlestick_master/firebase_options.dart";
import "package:candlestick_master/providers/auth_notifier.dart";
import "package:candlestick_master/providers/gamification_notifier.dart";
import "package:candlestick_master/providers/pattern_notifier.dart";
import "package:candlestick_master/providers/quiz_notifier.dart";
import "package:candlestick_master/providers/theme_notifier.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:candlestick_master/providers/user_progress_notifier.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

// =============================================================================
// Main Entry Point
// =============================================================================
// Initialize all services before running the app:
// 1. Firebase & Crashlytics (crash reporting, auth, firestore, analytics)
// 2. AdService (Google AdMob for monetization)
// 3. FCMService (Push notifications for engagement)
// 4. Meta SDK (Attribution tracking)
// 5. Providers (Auth, Theme, Gamification, UserProgress, TradeNotifier)
// =============================================================================

void main() async {
  runZonedGuarded<Future<void>>(() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught fatal errors from Flutter framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // PlatformDispatcher for async errors outside Flutter context
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize AdMob SDK for monetization
    await AdService.instance.initialize();
    await AdService.instance.startSession();

    // Initialize Meta (Facebook) SDK - app install tracking & ads attribution
    await MetaAnalyticsService.instance.initialize();
    await MetaAnalyticsService.instance.logAppOpen();

    // Initialize Firebase Cloud Messaging for push notifications
    FCMService.onNotificationTap = (data) {
      final route = data["route"];
      if (route is String && route.isNotEmpty) {
        appRouter.go(route);
        return;
      }

      final patternId = data["patternId"];
      if (patternId is String && patternId.isNotEmpty) {
        appRouter.go("/pattern/$patternId");
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
    final authNotifier = AuthNotifier();
    final tradeNotifier = TradeNotifier();

    final initialUid = authNotifier.uid ?? 'guest';

    // Load persisted preferences before app starts
    await Future.wait([
      themeNotifier.initialize(),
      userProgressNotifier.initialize(userId: initialUid),
      gamificationNotifier.initialize(userId: initialUid),
      tradeNotifier.initialize(userId: initialUid),
    ]);

    runApp(MyApp(
      themeNotifier: themeNotifier,
      userProgressNotifier: userProgressNotifier,
      gamificationNotifier: gamificationNotifier,
      authNotifier: authNotifier,
      tradeNotifier: tradeNotifier,
    ));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final UserProgressNotifier userProgressNotifier;
  final GamificationNotifier gamificationNotifier;
  final AuthNotifier authNotifier;
  final TradeNotifier tradeNotifier;

  const MyApp({
    super.key,
    required this.themeNotifier,
    required this.userProgressNotifier,
    required this.gamificationNotifier,
    required this.authNotifier,
    required this.tradeNotifier,
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
        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider.value(value: tradeNotifier),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: "Candlestick Master",
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
