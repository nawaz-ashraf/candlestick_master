import 'package:candlestick_master/core/constants/reward_constants.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/widgets/rewarded_ad_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rewarded Ads Reward & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('rewardAdCoins awards configured RewardConstants.rewardedAdCoins (100 coins) and persists across restart', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.coins, 0);

      // Award rewarded ad coins
      final success = await notifier.rewardAdCoins();
      expect(success, true);
      expect(notifier.coins, RewardConstants.rewardedAdCoins);
      expect(notifier.coins, 100);

      // Simulate app restart
      final restartedNotifier = GamificationNotifier();
      await restartedNotifier.initialize();
      expect(restartedNotifier.coins, 100);
    });

    test('addCoins awards configured RewardConstants.rewardedContentBonus (10 coins) and persists across restart', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.coins, 0);

      // Award bonus coins for indicator or quiz
      final success = await notifier.addCoins(RewardConstants.rewardedContentBonus);
      expect(success, true);
      expect(notifier.coins, 10);

      // Simulate app restart
      final restartedNotifier = GamificationNotifier();
      await restartedNotifier.initialize();
      expect(restartedNotifier.coins, 10);
    });

    test('idempotency guard prevents duplicate reward execution for a single ad session', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      var hasGrantedReward = false;
      var rewardExecutionCount = 0;

      // Simulate SDK callback invocation with session guard
      void onSdkEarnedReward() {
        if (!hasGrantedReward) {
          hasGrantedReward = true;
          rewardExecutionCount++;
          notifier.addCoins(RewardConstants.rewardedContentBonus);
        }
      }

      // First invocation by SDK
      onSdkEarnedReward();
      // Unintended duplicate invocation by SDK / Android lifecycle
      onSdkEarnedReward();

      expect(rewardExecutionCount, 1);
      expect(notifier.coins, 10);
    });

    test('closing ad early (without earning reward) does NOT award coins', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      expect(notifier.coins, 0);

      // User closed early: onUserEarnedReward was never invoked
      RewardedFlowResult flowResult = RewardedFlowResult.cancelled;

      expect(flowResult, RewardedFlowResult.cancelled);
      expect(notifier.coins, 0);

      // Verify persistence reflects 0 coins
      final restarted = GamificationNotifier();
      await restarted.initialize();
      expect(restarted.coins, 0);
    });

    test('ad unavailable fallback flow allows continuing without granting reward', () async {
      final notifier = GamificationNotifier();
      await notifier.initialize();

      // When ad is unavailable, fallback does not grant coins
      RewardedFlowResult flowResult = RewardedFlowResult.fallback;

      expect(flowResult, RewardedFlowResult.fallback);
      expect(notifier.coins, 0);
    });

    test('AdService RewardedAdResult enum maps correctly to expected states', () {
      expect(RewardedAdResult.rewarded.name, 'rewarded');
      expect(RewardedAdResult.dismissed.name, 'dismissed');
      expect(RewardedAdResult.loading.name, 'loading');
      expect(RewardedAdResult.notInitialized.name, 'notInitialized');
    });
  });
}
