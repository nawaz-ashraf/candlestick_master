import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/features/auth/login_screen.dart";
import "package:candlestick_master/features/home/home_screen.dart";
import "package:candlestick_master/features/compliance/privacy_policy_screen.dart";
import "package:candlestick_master/features/compliance/terms_of_service_screen.dart";
import "package:candlestick_master/features/profile/profile_screen.dart";
import "package:candlestick_master/providers/auth_notifier.dart";
import "package:candlestick_master/providers/gamification_notifier.dart";
import "package:candlestick_master/providers/pattern_notifier.dart";
import "package:candlestick_master/providers/theme_notifier.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:candlestick_master/providers/user_progress_notifier.dart";
import "package:candlestick_master/data/repositories/pattern_repository.dart";
import "package:candlestick_master/widgets/app_drawer.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

Widget createTestableWidget({
  required Widget child,
  ThemeNotifier? themeNotifier,
  GamificationNotifier? gamificationNotifier,
  UserProgressNotifier? userProgressNotifier,
  AuthNotifier? authNotifier,
  TradeNotifier? tradeNotifier,
  PatternsNotifier? patternsNotifier,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier ?? ThemeNotifier()),
      ChangeNotifierProvider<GamificationNotifier>.value(value: gamificationNotifier ?? GamificationNotifier()),
      ChangeNotifierProvider<UserProgressNotifier>.value(value: userProgressNotifier ?? UserProgressNotifier()),
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier ?? AuthNotifier()),
      ChangeNotifierProvider<TradeNotifier>.value(value: tradeNotifier ?? TradeNotifier()),
      ChangeNotifierProvider<PatternsNotifier>.value(value: patternsNotifier ?? PatternsNotifier(PatternRepository())),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("AppDrawer & Logo Tests", () {
    testWidgets("AppDrawer renders official logo asset, header, destinations, and triggers callback", (tester) async {
      int selectedDestination = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              selectedIndex: 0,
              onDestinationSelected: (index) {
                selectedDestination = index;
              },
            ),
          ),
        ),
      );

      // Verify Official Logo asset in Drawer
      final logoFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == "assets/images/app_logo.png",
      );
      expect(logoFinder, findsOneWidget);

      // Verify Drawer Header
      expect(find.text("Candlestick Master"), findsOneWidget);
      expect(find.text("Learn. Practice. Improve."), findsOneWidget);

      // Verify Destinations
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Learn"), findsOneWidget);
      expect(find.text("Quiz"), findsOneWidget);
      expect(find.text("Trading Journal"), findsOneWidget);
      expect(find.text("Challenge Arena"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);

      // Verify Version info & Android badge are removed from Drawer
      expect(find.text("Version 1.0.0"), findsNothing);
      expect(find.text("Android"), findsNothing);

      // Tap on Profile in Drawer
      await tester.tap(find.text("Profile"));
      await tester.pumpAndSettle();

      expect(selectedDestination, equals(5));
    });

    testWidgets("LoginScreen renders official logo asset in circular header", (tester) async {
      await tester.pumpWidget(createTestableWidget(
        child: const LoginScreen(),
      ));
      await tester.pump(const Duration(seconds: 12));

      // Verify Official Logo asset in Login Screen
      final logoFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == "assets/images/app_logo.png",
      );
      expect(logoFinder, findsOneWidget);
      expect(find.text("Welcome Back"), findsOneWidget);
    });
  });

  group("Bottom Navigation & Simplified Home AppBar Tests", () {
    testWidgets("HomeScreen bottom navigation renders only 4 destinations", (tester) async {
      final themeNotifier = ThemeNotifier();
      final gamificationNotifier = GamificationNotifier();
      final userProgressNotifier = UserProgressNotifier();
      final authNotifier = AuthNotifier();
      final tradeNotifier = TradeNotifier();
      final patternsNotifier = PatternsNotifier(PatternRepository());

      await tester.pumpWidget(createTestableWidget(
        child: const HomeScreen(),
        themeNotifier: themeNotifier,
        gamificationNotifier: gamificationNotifier,
        userProgressNotifier: userProgressNotifier,
        authNotifier: authNotifier,
        tradeNotifier: tradeNotifier,
        patternsNotifier: patternsNotifier,
      ));
      await tester.pump(const Duration(seconds: 12));

      // Verify only 4 items in bottom bar
      expect(find.text("Home"), findsWidgets);
      expect(find.text("Learn"), findsWidgets);
      expect(find.text("Quiz"), findsWidgets);
      expect(find.text("Journal"), findsWidgets);
    });

    testWidgets("Home AppBar has removed streak, coins, and share actions", (tester) async {
      final themeNotifier = ThemeNotifier();
      final gamificationNotifier = GamificationNotifier();
      final userProgressNotifier = UserProgressNotifier();
      final authNotifier = AuthNotifier();
      final tradeNotifier = TradeNotifier();
      final patternsNotifier = PatternsNotifier(PatternRepository());

      await tester.pumpWidget(createTestableWidget(
        child: const HomeScreen(),
        themeNotifier: themeNotifier,
        gamificationNotifier: gamificationNotifier,
        userProgressNotifier: userProgressNotifier,
        authNotifier: authNotifier,
        tradeNotifier: tradeNotifier,
        patternsNotifier: patternsNotifier,
      ));
      await tester.pump(const Duration(seconds: 12));

      // Home AppBar title & hamburger menu exist
      expect(find.widgetWithIcon(IconButton, Icons.menu), findsOneWidget);
      expect(find.text("Candlestick Master"), findsWidgets);

      // Home AppBar does NOT have share icon or fire icon in AppBar actions
      final homeAppBarFinder = find.byType(AppBar).first;
      final homeAppBar = tester.widget<AppBar>(homeAppBarFinder);
      expect(homeAppBar.actions, isNull);
    });
  });

  group("Redesigned ProfileScreen with Review and Share Tests", () {
    testWidgets("ProfileScreen renders Learning Cards, Account Settings, Review & Share, and NO Sync Now button", (tester) async {
      final themeNotifier = ThemeNotifier();
      final gamificationNotifier = GamificationNotifier();
      final userProgressNotifier = UserProgressNotifier();
      final authNotifier = AuthNotifier();
      final tradeNotifier = TradeNotifier();
      final patternsNotifier = PatternsNotifier(PatternRepository());

      await tester.pumpWidget(createTestableWidget(
        child: const ProfileScreen(),
        themeNotifier: themeNotifier,
        gamificationNotifier: gamificationNotifier,
        userProgressNotifier: userProgressNotifier,
        authNotifier: authNotifier,
        tradeNotifier: tradeNotifier,
        patternsNotifier: patternsNotifier,
      ));
      await tester.pump(const Duration(seconds: 12));

      // Profile title & Theme toggle in AppBar
      expect(find.text("Profile"), findsOneWidget);

      // Learning Progress Card
      expect(find.text("Learning Statistics"), findsOneWidget);
      expect(find.text("Patterns"), findsOneWidget);
      expect(find.text("Indicators"), findsOneWidget);
      expect(find.text("Challenges"), findsOneWidget);

      // Account Settings at the top
      final accountSettingsFinder = find.text("Account Settings");
      final learningStatsFinder = find.text("Learning Statistics");
      expect(accountSettingsFinder, findsOneWidget);
      expect(tester.getTopLeft(accountSettingsFinder).dy < tester.getTopLeft(learningStatsFinder).dy, isTrue);
      expect(find.text("Guest Trader"), findsOneWidget);
      expect(find.text("Sign in to backup your XP, streaks & journal"), findsOneWidget);

      // Write a Review & Share App Actions
      final shareAppFinder = find.text("Share App");
      expect(find.text("Write a Review"), findsOneWidget);
      expect(find.text("Enjoying Candlestick Master? Rate us on Google Play."), findsOneWidget);
      expect(shareAppFinder, findsOneWidget);
      expect(find.text("Invite friends to learn candlestick patterns and trading indicators."), findsOneWidget);

      // Privacy Policy & Terms of Service Actions
      final privacyPolicyFinder = find.text("Privacy Policy");
      final termsOfServiceFinder = find.text("Terms of Service");
      final quickActionsFinder = find.text("Quick Actions");

      expect(privacyPolicyFinder, findsOneWidget);
      expect(find.text("Learn how we collect, use, and protect your data."), findsOneWidget);
      expect(termsOfServiceFinder, findsOneWidget);
      expect(find.text("Read the terms and conditions for using the app."), findsOneWidget);

      // Verify strict vertical layout order:
      // Share App -> Privacy Policy -> Terms of Service -> Quick Actions
      expect(tester.getTopLeft(shareAppFinder).dy < tester.getTopLeft(privacyPolicyFinder).dy, isTrue);
      expect(tester.getTopLeft(privacyPolicyFinder).dy < tester.getTopLeft(termsOfServiceFinder).dy, isTrue);
      expect(tester.getTopLeft(termsOfServiceFinder).dy < tester.getTopLeft(quickActionsFinder).dy, isTrue);

      // Quick Actions
      expect(quickActionsFinder, findsOneWidget);
      expect(find.text("Practice Mistakes"), findsOneWidget);
      expect(find.text("Watch Ad → +100 Coins"), findsOneWidget);

      // VERIFY: Sync Now button is completely REMOVED
      expect(find.text("Sync Now"), findsNothing);
    });

    testWidgets("PrivacyPolicyScreen and TermsOfServiceScreen render headings and disclaimers", (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: PrivacyPolicyScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Privacy Policy"), findsWidgets);
      expect(find.text("1. Overview"), findsOneWidget);
      expect(find.text("3. Advertising (Google AdMob)"), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(
        home: TermsOfServiceScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Terms of Service"), findsOneWidget);
      expect(find.text("1. Acceptance of Terms"), findsOneWidget);
      expect(find.text("2. No Financial Advice"), findsOneWidget);
    });
  });
}
