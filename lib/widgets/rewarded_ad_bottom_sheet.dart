import 'dart:async';

import 'package:flutter/material.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:provider/provider.dart';

enum RewardedFlowResult {
  success,
  fallback,
  cancelled,
}

class RewardedAdBottomSheet extends StatefulWidget {
  final String title;
  final String description;
  final int rewardAmount;
  final FutureOr<void> Function()? onRewardEarned;

  const RewardedAdBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.rewardAmount,
    this.onRewardEarned,
  });

  static Future<RewardedFlowResult> show(
    BuildContext context, {
    required String title,
    required String description,
    required int rewardAmount,
    FutureOr<void> Function()? onRewardEarned,
  }) async {
    final result = await showModalBottomSheet<RewardedFlowResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RewardedAdBottomSheet(
        title: title,
        description: description,
        rewardAmount: rewardAmount,
        onRewardEarned: onRewardEarned,
      ),
    );
    return result ?? RewardedFlowResult.cancelled;
  }

  @override
  State<RewardedAdBottomSheet> createState() => _RewardedAdBottomSheetState();
}

class _RewardedAdBottomSheetState extends State<RewardedAdBottomSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _showAd() async {
    if (_isLoading) return;

    debugPrint(
        'RewardedAdBottomSheet: User opted in to watch ad (reward: +${widget.rewardAmount} coins)');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ── Step 1: Wait for the ad to be fully loaded ──────────────────────────
    // This ensures we NEVER call .show() on an unavailable ad.
    final isReady = await AdService.instance.waitForRewardedAd(
      timeout: const Duration(seconds: 10),
    );

    if (!mounted) return;

    if (!isReady) {
      debugPrint('RewardedAdBottomSheet: Rewarded ad unavailable after waiting');
      setState(() {
        _isLoading = false;
        _errorMessage = "Ad isn't available right now. Please try again later.";
      });
      return;
    }

    // ── Step 2: Show the ad with reward-delivery callback ───────────────────
    final gamification = context.read<GamificationNotifier>();
    final result = await AdService.instance.showRewardedAd(
      onUserEarnedReward: (reward) async {
        debugPrint(
            'RewardedAdBottomSheet: onUserEarnedReward received from AdMob SDK');
        if (widget.onRewardEarned != null) {
          await widget.onRewardEarned!();
        } else if (widget.rewardAmount > 0) {
          await gamification.addCoins(widget.rewardAmount);
        }
      },
    );

    if (!mounted) return;

    debugPrint('RewardedAdBottomSheet: Ad presentation finished with result: $result');

    switch (result) {
      case RewardedAdResult.rewarded:
        Navigator.of(context).pop(RewardedFlowResult.success);
      case RewardedAdResult.dismissed:
        Navigator.of(context).pop(RewardedFlowResult.cancelled);
      case RewardedAdResult.loading:
      case RewardedAdResult.notInitialized:
        // Edge case: ad became unavailable between wait and show.
        setState(() {
          _isLoading = false;
          _errorMessage = "Ad couldn't be shown. Please try again.";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bearish.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.bearish,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(RewardedFlowResult.fallback),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showAd,
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ] else if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text(
                'Loading advertisement...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+${widget.rewardAmount} Coins',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .pop(RewardedFlowResult.cancelled),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showAd,
                      child: const Text('Watch Ad'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
