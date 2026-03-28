import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/services/storage_service.dart';
import 'package:candlestick_master/models/habit_user_progress.dart'
    as habit_model;
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GamificationNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists gamification data across app restart', () async {
      final firstRunNotifier = GamificationNotifier();
      await firstRunNotifier.initialize();

      await firstRunNotifier.completeLesson('hammer');
      await firstRunNotifier.recordQuizAnswer('hammer', true);

      expect(firstRunNotifier.xp, 30);
      expect(firstRunNotifier.completedLessons, contains('hammer'));

      final secondRunNotifier = GamificationNotifier();
      await secondRunNotifier.initialize();

      expect(secondRunNotifier.xp, 30);
      expect(secondRunNotifier.completedLessons, contains('hammer'));
    });

    test('resets streak on startup when user missed at least one day',
        () async {
      final storage = StorageService();
      await storage.saveGamificationData(
        const habit_model.UserProgress(
          streak: 5,
          bestStreak: 8,
          lastActiveDate: '2000-01-01',
          dailyChallengeCompleted: true,
          dailyChallengeDate: '2000-01-01',
        ),
      );

      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.streak, 0);
      expect(notifier.bestStreak, 8);
      expect(notifier.isDailyChallengeAvailable, true);
    });

    test('awards lesson XP once per unique lesson completion', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      await notifier.completeLesson('doji');
      await notifier.completeLesson('doji');

      expect(notifier.xp, 10);
      expect(notifier.completedLessons.where((id) => id == 'doji').length, 1);
    });

    test('awards quiz XP correctly and tracks wrong answers for revision',
        () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      await notifier.recordQuizAnswer('engulfing', false);
      expect(notifier.xp, 0);
      expect(notifier.wrongAnswers, contains('engulfing'));

      await notifier.recordQuizAnswer('engulfing', true);
      expect(notifier.xp, 20);
      expect(notifier.wrongAnswers, isNot(contains('engulfing')));

      await notifier.recordQuizAnswer('static_q1', false);
      expect(notifier.wrongAnswers, isNot(contains('static_q1')));
    });

    test('completes daily challenge only once per day', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      await notifier.completeDailyChallenge();
      final firstXp = notifier.xp;
      final firstCoins = notifier.coins;

      await notifier.completeDailyChallenge();

      expect(firstXp, 30);
      expect(firstCoins, 50);
      expect(notifier.xp, firstXp);
      expect(notifier.coins, firstCoins);
      expect(notifier.isDailyChallengeCompletedToday, true);
    });

    test('loads safe defaults when persisted JSON is malformed', () async {
      SharedPreferences.setMockInitialValues(
        {'gamification_data': '{broken-json'},
      );

      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.xp, 0);
      expect(notifier.coins, 0);
      expect(notifier.streak, 0);
      expect(notifier.completedLessons, isEmpty);
      expect(notifier.wrongAnswers, isEmpty);
    });

    test('seeds user id and base difficulty unlock keys on initialize',
        () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.userId, isNotEmpty);
      expect(
        notifier.unlockedDifficulties,
        contains(
          LearningConstants.unlockKey(
            module: LearningConstants.modulePattern,
            difficulty: ContentDifficulty.basic,
          ),
        ),
      );
      expect(
        notifier.unlockedDifficulties,
        contains(
          LearningConstants.unlockKey(
            module: LearningConstants.moduleChallenge,
            difficulty: ContentDifficulty.basic,
          ),
        ),
      );
      expect(
        notifier.unlockedDifficulties,
        contains(
          LearningConstants.unlockKey(
            module: LearningConstants.moduleIndicator,
            difficulty: ContentDifficulty.basic,
          ),
        ),
      );
    });

    test('assigns one deterministic daily lesson per day', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      final lessonIds = ['lesson_a', 'lesson_b', 'lesson_c'];
      final first = await notifier.ensureDailyLesson(lessonIds);
      final second = await notifier.ensureDailyLesson(lessonIds);

      expect(first, isNotEmpty);
      expect(lessonIds, contains(first));
      expect(second, first);
      expect(notifier.dailyLessonId, first);
    });

    test('awards indicator completion XP once per indicator', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      await notifier.completeIndicator('indicator_rsi');
      await notifier.completeIndicator('indicator_rsi');

      expect(notifier.completedIndicators, contains('indicator_rsi'));
      expect(notifier.xp, 10);
    });

    test('awards challenge completion XP once per challenge id', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      await notifier.completeChallenge(
          challengeId: 'challenge_1', xpReward: 24);
      await notifier.completeChallenge(
          challengeId: 'challenge_1', xpReward: 24);

      expect(notifier.completedChallenges, contains('challenge_1'));
      expect(notifier.xp, 24);
    });
  });
}
