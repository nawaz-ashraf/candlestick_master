import 'package:candlestick_master/core/services/storage_service.dart';
import 'package:candlestick_master/models/habit_user_progress.dart';
import 'package:candlestick_master/models/trade_model.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/trade_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Account Data Isolation - StorageService', () {
    test('User A and User B data are stored under distinct keys', () async {
      final storage = StorageService();

      const userAProgress = UserProgress(
        userId: 'user_A',
        xp: 1500,
        coins: 350,
        streak: 5,
        completedLessons: ['hammer_pattern', 'doji_reversal'],
      );

      const userBProgress = UserProgress(
        userId: 'user_B',
        xp: 200,
        coins: 50,
        streak: 1,
        completedLessons: ['intro_candlesticks'],
      );

      // Save both
      await storage.saveGamificationData(userAProgress, userId: 'user_A');
      await storage.saveGamificationData(userBProgress, userId: 'user_B');

      // Load User A
      final loadedA = await storage.loadGamificationData(userId: 'user_A');
      expect(loadedA.userId, equals('user_A'));
      expect(loadedA.xp, equals(1500));
      expect(loadedA.coins, equals(350));
      expect(loadedA.completedLessons, contains('hammer_pattern'));
      expect(loadedA.completedLessons, isNot(contains('intro_candlesticks')));

      // Load User B
      final loadedB = await storage.loadGamificationData(userId: 'user_B');
      expect(loadedB.userId, equals('user_B'));
      expect(loadedB.xp, equals(200));
      expect(loadedB.coins, equals(50));
      expect(loadedB.completedLessons, contains('intro_candlesticks'));
      expect(loadedB.completedLessons, isNot(contains('hammer_pattern')));

      // Clear User A does not affect User B
      await storage.clearGamificationData(userId: 'user_A');
      final afterClearA = await storage.loadGamificationData(userId: 'user_A');
      expect(afterClearA.xp, equals(0));

      final checkB = await storage.loadGamificationData(userId: 'user_B');
      expect(checkB.xp, equals(200));
    });
  });

  group('Account Data Isolation - UserProgressNotifier (Learned Patterns & Quiz)', () {
    test('Test A & B: User B does not see User A learned patterns after logout/switch', () async {
      final notifier = UserProgressNotifier();

      // 1. User A logs in
      await notifier.initialize(userId: 'user_A');
      await notifier.markAsLearned('hammer');
      await notifier.markAsLearned('bullish_engulfing');
      await notifier.markAsLearned('morning_star');
      await notifier.recordQuizBatch(totalAnswered: 10, correctCount: 9);

      expect(notifier.learnedCount, equals(3));
      expect(notifier.isPatternLearned('hammer'), isTrue);
      expect(notifier.totalQuestions, equals(10));
      expect(notifier.correctAnswers, equals(9));

      // 2. User A logs out
      notifier.clearOnSignOut();
      expect(notifier.learnedCount, equals(0), reason: 'In-memory state must be cleared on sign out');
      expect(notifier.totalQuestions, equals(0));

      // 3. User B logs in
      await notifier.switchUser('user_B');
      expect(notifier.learnedCount, equals(0), reason: 'User B must not see User A learned patterns');
      expect(notifier.isPatternLearned('hammer'), isFalse);
      expect(notifier.totalQuestions, equals(0));
      expect(notifier.correctAnswers, equals(0));

      // 4. User B learns a different pattern
      await notifier.markAsLearned('shooting_star');
      expect(notifier.learnedCount, equals(1));
      expect(notifier.isPatternLearned('shooting_star'), isTrue);
      expect(notifier.isPatternLearned('hammer'), isFalse);

      // 5. User B logs out and User A logs back in (Persistence check)
      notifier.clearOnSignOut();
      await notifier.switchUser('user_A');
      expect(notifier.learnedCount, equals(3), reason: 'User A patterns must be intact');
      expect(notifier.isPatternLearned('hammer'), isTrue);
      expect(notifier.isPatternLearned('bullish_engulfing'), isTrue);
      expect(notifier.isPatternLearned('shooting_star'), isFalse, reason: 'User A must not have User B pattern');
      expect(notifier.totalQuestions, equals(10));
      expect(notifier.correctAnswers, equals(9));
    });
  });

  group('Account Data Isolation - GamificationNotifier (XP, Coins, Streaks, Lessons)', () {
    test('User B starts with fresh state and does not inherit User A gamification progress', () async {
      final notifier = GamificationNotifier();

      // 1. User A earns progress
      await notifier.initialize(userId: 'user_A');
      await notifier.addXp(600);
      await notifier.addCoins(250);
      await notifier.completeLesson('pattern_marubozu');

      expect(notifier.xp, equals(610)); // 600 + 10 XP for lesson
      expect(notifier.coins, equals(250));
      expect(notifier.completedLessons, contains('pattern_marubozu'));

      // 2. User A signs out
      await notifier.clearOnSignOut();
      expect(notifier.currentUserId, equals('guest'));

      // 3. User B signs in
      await notifier.switchUser('user_B');
      expect(notifier.currentUserId, equals('user_B'));
      expect(notifier.xp, equals(0), reason: 'User B must start with 0 XP');
      expect(notifier.coins, equals(0), reason: 'User B must start with 0 Coins');
      expect(notifier.completedLessons, isNot(contains('pattern_marubozu')), reason: 'User B must have empty completed lessons');

      // 4. User B earns progress
      await notifier.addXp(120);
      await notifier.addCoins(40);
      expect(notifier.xp, equals(120));
      expect(notifier.coins, equals(40));

      // 5. Switch back to User A
      await notifier.switchUser('user_A');
      expect(notifier.xp, equals(610), reason: 'User A XP must be preserved');
      expect(notifier.coins, equals(250), reason: 'User A coins must be preserved');
      expect(notifier.completedLessons, contains('pattern_marubozu'));
    });
  });

  group('Account Data Isolation - Trading Journal & TradeNotifier', () {
    test('Trade model requires and serializes userId correctly', () {
      final tradeA = Trade(
        id: 't-1',
        userId: 'user_A',
        symbol: 'BTC/USDT',
        tradeType: TradeType.long,
        status: TradeStatus.closed,
        entryPrice: 60000,
        exitPrice: 65000,
        quantity: 1,
        entryDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(tradeA.userId, equals('user_A'));

      final json = tradeA.toJson();
      expect(json['userId'], equals('user_A'));

      final fromJson = Trade.fromJson(json);
      expect(fromJson.userId, equals('user_A'));

      final copy = tradeA.copyWith(userId: 'user_B');
      expect(copy.userId, equals('user_B'));
    });

    test('TradeNotifier clears in-memory trades on sign out and scopes user identity', () async {
      final tradeNotifier = TradeNotifier();

      // Clear on sign out resets in-memory trades list
      tradeNotifier.clearOnSignOut();
      expect(tradeNotifier.trades, isEmpty);
      expect(tradeNotifier.currentUserId, equals('guest'));
    });
  });
}
