// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:candlestick_master/presentation/providers/theme_notifier.dart';
import 'package:candlestick_master/presentation/providers/user_progress_notifier.dart';
import 'package:candlestick_master/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create providers for test
    final themeNotifier = ThemeNotifier();
    final userProgressNotifier = UserProgressNotifier();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      themeNotifier: themeNotifier,
      userProgressNotifier: userProgressNotifier,
    ));

    // Verify app starts without errors
    expect(find.text('Candlestick Master'), findsOneWidget);
  });
}
