import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/fcm_service.dart';
import 'presentation/providers/pattern_notifier.dart';
import 'presentation/providers/quiz_notifier.dart';
import 'data/repositories/pattern_repository.dart';

// =============================================================================
// Main Entry Point
// =============================================================================
// Initialize all services before running the app:
// 1. Firebase (required for FCM, Firestore, Auth)
// 2. AdService (Google AdMob for monetization)
// 3. FCMService (Push notifications for engagement)
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
  
  // Initialize Firebase Cloud Messaging for push notifications
  await FCMService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatternsNotifier(PatternRepository())),
        ChangeNotifierProvider(create: (_) => QuizNotifier()),
      ],
      child: MaterialApp.router(
        title: 'Candlestick Master',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
