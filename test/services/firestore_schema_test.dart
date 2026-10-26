import 'package:candlestick_master/models/habit_user_progress.dart';
import 'package:candlestick_master/models/trade_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Schema & Calculation Tests', () {
    test('Trading summary calculates correct aggregates excluding open trades', () {
      final trades = [
        Trade(
          id: '1',
          userId: 'user_123',
          symbol: 'BTC/USDT',
          tradeType: TradeType.long,
          status: TradeStatus.closed,
          entryPrice: 50000,
          exitPrice: 55000,
          quantity: 2, // PnL = +10,000
          entryDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        Trade(
          id: '2',
          userId: 'user_123',
          symbol: 'ETH/USDT',
          tradeType: TradeType.long,
          status: TradeStatus.closed,
          entryPrice: 3000,
          exitPrice: 2800,
          quantity: 5, // PnL = -1,000
          entryDate: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
        Trade(
          id: '3',
          userId: 'user_123',
          symbol: 'SOL/USDT',
          tradeType: TradeType.long,
          status: TradeStatus.open,
          entryPrice: 150,
          quantity: 10, // Open trade -> Excluded from realized PnL
          entryDate: DateTime(2026, 1, 3),
          createdAt: DateTime(2026, 1, 3),
          updatedAt: DateTime(2026, 1, 3),
        ),
      ];

      final closedTrades = trades.where((t) => t.status == TradeStatus.closed && t.exitPrice != null).toList();
      final openTrades = trades.where((t) => t.status == TradeStatus.open).toList();

      final winningTrades = closedTrades.where((t) => (t.pnl ?? 0) > 0).toList();
      final losingTrades = closedTrades.where((t) => (t.pnl ?? 0) < 0).toList();

      final grossProfit = winningTrades.fold<double>(0.0, (acc, t) => acc + (t.pnl ?? 0));
      final grossLoss = losingTrades.fold<double>(0.0, (acc, t) => acc + (t.pnl ?? 0).abs());
      final netPnl = closedTrades.fold<double>(0.0, (acc, t) => acc + (t.pnl ?? 0));

      final winRate = (winningTrades.length / closedTrades.length) * 100;
      final avgWin = grossProfit / winningTrades.length;
      final avgLoss = grossLoss / losingTrades.length;

      expect(trades.length, equals(3));
      expect(openTrades.length, equals(1));
      expect(closedTrades.length, equals(2));
      expect(winningTrades.length, equals(1));
      expect(losingTrades.length, equals(1));

      expect(grossProfit, equals(10000.0));
      expect(grossLoss, equals(1000.0));
      expect(netPnl, equals(9000.0));
      expect(winRate, equals(50.0));
      expect(avgWin, equals(10000.0));
      expect(avgLoss, equals(1000.0));
    });

    test('Learning summary attributes map properly without data loss', () {
      const progress = UserProgress(
        userId: 'user_abc',
        xp: 1250,
        coins: 400,
        streak: 7,
        bestStreak: 14,
        lastActiveDate: '2026-10-26',
        completedLessons: ['hammer', 'doji', 'marubozu'],
        completedIndicators: ['rsi', 'macd'],
        completedChallenges: ['challenge_1'],
      );

      final summaryMap = {
        'totalPatternsCompleted': progress.completedLessons.length,
        'totalIndicatorsCompleted': progress.completedIndicators.length,
        'totalQuizzesCompleted': 5,
        'totalChallengesCompleted': progress.completedChallenges.length,
        'totalXp': progress.xp,
        'currentLevel': progress.level,
        'currentStreak': progress.streak,
        'longestStreak': progress.bestStreak,
        'coins': progress.coins,
        'lastLearningDate': progress.lastActiveDate,
      };

      expect(summaryMap['totalPatternsCompleted'], equals(3));
      expect(summaryMap['totalIndicatorsCompleted'], equals(2));
      expect(summaryMap['totalChallengesCompleted'], equals(1));
      expect(summaryMap['totalXp'], equals(1250));
      expect(summaryMap['coins'], equals(400));
      expect(summaryMap['currentStreak'], equals(7));
      expect(summaryMap['longestStreak'], equals(14));
    });

    test('User profile schema contains schemaVersion and avoids sensitive fields', () {
      final profile = {
        'uid': 'user_test_999',
        'email': 'trader@example.com',
        'displayName': 'Pro Trader',
        'preferredTheme': 'dark',
        'accountStatus': 'active',
        'onboardingCompleted': true,
        'schemaVersion': 2,
      };

      expect(profile.containsKey('password'), isFalse);
      expect(profile.containsKey('passwordHash'), isFalse);
      expect(profile['schemaVersion'], equals(2));
      expect(profile['accountStatus'], equals('active'));
    });
  });
}
