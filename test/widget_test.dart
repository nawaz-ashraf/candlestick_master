import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/theme_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Provider wiring smoke test', (WidgetTester tester) async {
    final themeNotifier = ThemeNotifier();
    final userProgressNotifier = UserProgressNotifier();
    final gamificationNotifier = GamificationNotifier();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeNotifier),
          ChangeNotifierProvider.value(value: userProgressNotifier),
          ChangeNotifierProvider.value(value: gamificationNotifier),
        ],
        child: MaterialApp(
          home: Consumer3<ThemeNotifier, UserProgressNotifier,
              GamificationNotifier>(
            builder: (context, theme, progress, gamification, _) {
              final themeLabel = theme.isDarkMode ? 'dark' : 'light';
              return Text(
                  'ready-$themeLabel-${progress.learnedCount}-${gamification.level}');
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('ready-'), findsOneWidget);
  });
}
