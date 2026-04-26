// =============================================================================
// MetaAnalyticsService — Meta (Facebook) SDK Event Tracking
// =============================================================================
//
// PURPOSE
// -------
// Centralises every Meta / Facebook App-Events call so the rest of the
// codebase never imports `facebook_app_events` directly.  All you need to do
// is call the static helpers on this class.
//
// SETUP REMINDER
// --------------
// Before this service does anything useful you must supply real credentials:
//   • android/app/src/main/res/values/strings.xml
//     → facebook_app_id         (e.g. "1234567890123456")
//     → facebook_client_token   (e.g. "abcdef1234567890...")
//     → fb_login_protocol_scheme (e.g. "fb1234567890123456")
//
//   • iOS: ios/Runner/Info.plist
//     → FacebookAppID, FacebookClientToken, FacebookDisplayName
//     → CFBundleURLSchemes entry with your fb[APP_ID] scheme
//
// Events visible in: Meta Events Manager
//   https://www.facebook.com/events_manager2
// =============================================================================

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Singleton wrapper around [FacebookAppEvents].
///
/// Usage:
/// ```dart
/// // In main() — after WidgetsFlutterBinding.ensureInitialized()
/// await MetaAnalyticsService.instance.initialize();
///
/// // Anywhere in the app
/// MetaAnalyticsService.instance.logAppOpen();
/// MetaAnalyticsService.instance.logCustomEvent('SubscriptionStarted');
/// ```
class MetaAnalyticsService {
  MetaAnalyticsService._();
  static final MetaAnalyticsService instance = MetaAnalyticsService._();

  late final FacebookAppEvents _fb;
  bool _initialized = false;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Must be called once from [main()] before [runApp].
  ///
  /// Sets the Graph API version to v24.0 (workaround for FB SDK v18.x shipping
  /// with a deprecated default — see pub.dev package notes).
  Future<void> initialize() async {
    if (_initialized) return;

    _fb = FacebookAppEvents();

    // Override Graph API version — plugin default is already v24.0 but we
    // set it explicitly so the behaviour doesn't change across SDK updates.
    await _fb.setGraphApiVersion('v24.0');

    // Activate the app — this is the "AppLaunch" signal Meta uses to confirm
    // the attribution window for an install campaign.
    await _fb.activateApp();

    _initialized = true;
    _log('✅ Meta SDK initialized and app activated.');
  }

  // ─── Standard  Events ──────────────────────────────────────────────────────

  /// Call once when the user first opens the app (after install attribution
  /// has fired).  Also fired automatically by [initialize()], but you can call
  /// this again on each cold start if you want session-level data.
  Future<void> logAppOpen() async {
    _assertInit();
    await _fb.logEvent(
      name: 'app_opened',
      parameters: {
        'source': 'cold_start',
      },
    );
    _log('📲 logAppOpen fired');
  }

  /// Logs the standard "Achieved Level" event so Meta Ads can optimise for
  /// engaged users.
  Future<void> logLevelAchieved(int level) async {
    _assertInit();
    // Official Meta event name: https://developers.facebook.com/docs/app-events/reference#standard-events
    await _fb.logEvent(
      name: 'fb_mobile_achieved_level',
      parameters: {
        'fb_level': level.toString(),
      },
    );
    _log('🏆 logLevelAchieved: level=$level');
  }

  /// Logs when the user completes a quiz / learning module.
  Future<void> logTutorialComplete() async {
    _assertInit();
    await _fb.logEvent(
      name: 'fb_mobile_tutorial_completion',
      parameters: {
        'fb_success': '1',
      },
    );
    _log('🎓 logTutorialComplete fired');
  }

  /// Logs when the user views a candlestick pattern.
  Future<void> logPatternViewed(String patternName) async {
    _assertInit();
    await _fb.logEvent(
      name: 'fb_mobile_content_view',
      parameters: {
        'fb_content_type': 'candlestick_pattern',
        'fb_content_id': patternName,
      },
    );
    _log('👁 logPatternViewed: $patternName');
  }

  /// Logs when the user starts a quiz.
  Future<void> logQuizStarted(String quizType) async {
    _assertInit();
    await _fb.logEvent(
      name: 'quiz_started',
      parameters: {
        'quiz_type': quizType,
      },
    );
    _log('📝 logQuizStarted: $quizType');
  }

  /// Logs when the user completes a quiz with a score.
  Future<void> logQuizCompleted({
    required String quizType,
    required int score,
    required int totalQuestions,
  }) async {
    _assertInit();
    await _fb.logEvent(
      name: 'quiz_completed',
      parameters: {
        'quiz_type': quizType,
        'score': score.toString(),
        'total_questions': totalQuestions.toString(),
        'pass_rate': '${((score / totalQuestions) * 100).toStringAsFixed(0)}%',
      },
    );
    _log('✅ logQuizCompleted: $quizType score=$score/$totalQuestions');
  }

  /// Logs the standard "Subscribe" event — use this for any premium / pro
  /// plan purchase to feed Meta's value-based conversion optimisation.
  Future<void> logSubscriptionStarted({
    required String planName,
    required double price,
    String currency = 'USD',
  }) async {
    _assertInit();
    // 'Subscribe' is Meta's standard conversion event for subscriptions
    await _fb.logEvent(
      name: 'Subscribe',
      parameters: {
        'fb_order_id': planName,
        'fb_currency': currency,
        'fb_num_items': '1',
        'plan_name': planName,
        'price': price.toStringAsFixed(2),
      },
    );
    _log('💳 logSubscriptionStarted: $planName @ $price $currency');
  }

  /// Logs an in-app purchase (standard Meta commerce event).
  Future<void> logPurchase({
    required double amount,
    required String currency,
    String? itemId,
  }) async {
    _assertInit();
    await _fb.logPurchase(amount: amount, currency: currency, parameters: {
      if (itemId != null) 'fb_content_id': itemId,
    });
    _log('🛒 logPurchase: $amount $currency${itemId != null ? " item=$itemId" : ""}');
  }

  // ─── Custom Events ─────────────────────────────────────────────────────────

  /// Generic helper for any custom event not covered by the convenience
  /// methods above.
  ///
  /// [name]       — must be ≤ 40 characters, alphanumeric / underscore only.
  /// [parameters] — optional key-value map (values must be String).
  ///
  /// Example:
  /// ```dart
  /// MetaAnalyticsService.instance.logCustomEvent(
  ///   'DailyStreakMilestone',
  ///   parameters: {'streak_days': '7'},
  /// );
  /// ```
  Future<void> logCustomEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    _assertInit();
    await _fb.logEvent(name: name, parameters: parameters);
    _log('📊 logCustomEvent: $name params=${parameters ?? {}}');
  }

  // ─── Privacy helpers ───────────────────────────────────────────────────────

  /// Call this if your app collects user consent (GDPR / CCPA).
  /// Disables automatic events & data collection until the user consents.
  Future<void> disableAutoEvents() async {
    _assertInit();
    await _fb.setAutoLogAppEventsEnabled(false);
    _log('🔒 Auto log events DISABLED (waiting for consent)');
  }

  /// Re-enables automatic events after user has granted consent.
  Future<void> enableAutoEvents() async {
    _assertInit();
    await _fb.setAutoLogAppEventsEnabled(true);
    _log('✅ Auto log events ENABLED (consent granted)');
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  void _assertInit() {
    assert(
      _initialized,
      'MetaAnalyticsService.initialize() must be called before using the service.',
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[MetaAnalytics] $message');
  }
}
