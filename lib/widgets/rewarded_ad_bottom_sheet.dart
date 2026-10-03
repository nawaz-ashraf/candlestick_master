import 'package:flutter/material.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';

enum RewardedFlowResult {
  success,
  fallback,
  cancelled,
}

class RewardedAdBottomSheet extends StatefulWidget {
  final String title;
  final String description;
  final int rewardAmount;

  const RewardedAdBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.rewardAmount,
  });

  static Future<RewardedFlowResult> show(
    BuildContext context, {
    required String title,
    required String description,
    required int rewardAmount,
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int attempts = 0;
    while (attempts < 3) {
      //bool rewardEarned = false;
      final result = await AdService.instance.showRewardedAd(
        onRewarded: () {
          //rewardEarned = true;
        },
      );

      if (result == RewardedAdResult.rewarded) {
        if (!mounted) return;
        Navigator.of(context).pop(RewardedFlowResult.success);
        return;
      } else if (result == RewardedAdResult.dismissed) {
        if (!mounted) return;
        Navigator.of(context).pop(RewardedFlowResult.cancelled);
        return;
      } else if (result == RewardedAdResult.loading ||
          result == RewardedAdResult.notInitialized) {
        attempts++;
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = "Ad isn't available right now.";
    });
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
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(RewardedFlowResult.fallback),
                child: const Text('Continue'),
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
