// =============================================================================
// AnalyticsService - Firebase Analytics Wrapper
// =============================================================================
// Centralized analytics event logging for user engagement tracking.
// All events follow Firebase recommended naming conventions.
// =============================================================================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  // ============================================
  // Authentication Events
  // ============================================

  Future<void> logLogin({String method = 'email'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('AnalyticsService: logLogin error – $e');
    }
  }

  Future<void> logSignUp({String method = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('AnalyticsService: logSignUp error – $e');
    }
  }

  // ============================================
  // Learning Events
  // ============================================

  Future<void> logLessonComplete({
    required String lessonId,
    required String lessonType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_complete',
        parameters: {
          'lesson_id': lessonId,
          'lesson_type': lessonType,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: logLessonComplete error – $e');
    }
  }

  Future<void> logIndicatorComplete({required String indicatorId}) async {
    try {
      await _analytics.logEvent(
        name: 'indicator_complete',
        parameters: {'indicator_id': indicatorId},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logIndicatorComplete error – $e');
    }
  }

  // ============================================
  // Quiz Events
  // ============================================

  Future<void> logQuizStart({required String difficulty}) async {
    try {
      await _analytics.logEvent(
        name: 'quiz_start',
        parameters: {'difficulty': difficulty},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logQuizStart error – $e');
    }
  }

  Future<void> logQuizComplete({
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'quiz_complete',
        parameters: {
          'difficulty': difficulty,
          'score': score,
          'total_questions': totalQuestions,
          'accuracy': totalQuestions > 0
              ? ((score / totalQuestions) * 100).round()
              : 0,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: logQuizComplete error – $e');
    }
  }

  // ============================================
  // Trading Journal Events
  // ============================================

  Future<void> logTradeCreated({required String tradeType}) async {
    try {
      await _analytics.logEvent(
        name: 'trade_created',
        parameters: {'trade_type': tradeType},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logTradeCreated error – $e');
    }
  }

  Future<void> logTradeEdited() async {
    try {
      await _analytics.logEvent(name: 'trade_edited');
    } catch (e) {
      debugPrint('AnalyticsService: logTradeEdited error – $e');
    }
  }

  Future<void> logTradeDeleted() async {
    try {
      await _analytics.logEvent(name: 'trade_deleted');
    } catch (e) {
      debugPrint('AnalyticsService: logTradeDeleted error – $e');
    }
  }

  // ============================================
  // Monetization Events
  // ============================================

  Future<void> logAdWatched({required String adType}) async {
    try {
      await _analytics.logEvent(
        name: 'ad_watched',
        parameters: {'ad_type': adType},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logAdWatched error – $e');
    }
  }

  Future<void> logCoinEarned({
    required int amount,
    required String source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'coin_earned',
        parameters: {
          'amount': amount,
          'source': source,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: logCoinEarned error – $e');
    }
  }

  // ============================================
  // Additional Engagement Events
  // ============================================

  Future<void> logLessonOpened({
    required String lessonId,
    String? lessonType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_opened',
        parameters: {
          'lesson_id': lessonId,
          if (lessonType != null) 'lesson_type': lessonType,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: logLessonOpened error – $e');
    }
  }

  Future<void> logIndicatorOpened({required String indicatorId}) async {
    try {
      await _analytics.logEvent(
        name: 'indicator_opened',
        parameters: {'indicator_id': indicatorId},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logIndicatorOpened error – $e');
    }
  }

  Future<void> logJournalOpened() async {
    try {
      await _analytics.logEvent(name: 'journal_opened');
    } catch (e) {
      debugPrint('AnalyticsService: logJournalOpened error – $e');
    }
  }

  Future<void> logChallengeStarted({required String challengeId}) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_started',
        parameters: {'challenge_id': challengeId},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logChallengeStarted error – $e');
    }
  }

  Future<void> logDailyStreakMaintained({required int streak}) async {
    try {
      await _analytics.logEvent(
        name: 'daily_streak_maintained',
        parameters: {'streak': streak},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logDailyStreakMaintained error – $e');
    }
  }

  // ============================================
  // User Properties
  // ============================================

  Future<void> setUserProperties({
    String? uid,
    int? level,
    int? streak,
  }) async {
    try {
      if (uid != null) {
        await _analytics.setUserId(id: uid);
      }
      if (level != null) {
        await _analytics.setUserProperty(
          name: 'user_level',
          value: level.toString(),
        );
      }
      if (streak != null) {
        await _analytics.setUserProperty(
          name: 'current_streak',
          value: streak.toString(),
        );
      }
    } catch (e) {
      debugPrint('AnalyticsService: setUserProperties error – $e');
    }
  }

  // ============================================
  // Challenge Events
  // ============================================

  Future<void> logChallengeComplete({required String challengeId}) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_complete',
        parameters: {'challenge_id': challengeId},
      );
    } catch (e) {
      debugPrint('AnalyticsService: logChallengeComplete error – $e');
    }
  }

  Future<void> logDailyChallengeComplete() async {
    try {
      await _analytics.logEvent(name: 'daily_challenge_complete');
    } catch (e) {
      debugPrint('AnalyticsService: logDailyChallengeComplete error – $e');
    }
  }
}
