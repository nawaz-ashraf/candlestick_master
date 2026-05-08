// =============================================================================
// ProfileScreen - User Profile & Stats Hub
// =============================================================================
// Shows user level, XP, coins, streaks, achievements, and provides access
// to revision mode and rewarded ads.
// =============================================================================

import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/data/repositories/lesson_repository.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:candlestick_master/providers/theme_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                onPressed: () =>
                    themeNotifier.toggleTheme(!themeNotifier.isDarkMode),
                icon: Icon(themeNotifier.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                tooltip: themeNotifier.isDarkMode
                    ? "Switch to Light Mode"
                    : "Switch to Dark Mode",
              );
            },
          ),
        ],
      ),
      body: Consumer2<GamificationNotifier, UserProgressNotifier>(
        builder: (context, gamification, progress, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level Card
                _buildLevelCard(context, gamification),
                const SizedBox(height: 20),

                // Stats Grid
                _buildStatsRow(context, gamification),
                const SizedBox(height: 20),

                // Quick Actions
                _buildSectionHeader(context, "Quick Actions"),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  "Practice Mistakes",
                  "${gamification.wrongAnswers.length} questions to review",
                  Icons.replay_circle_filled,
                  AppColors.bearish,
                  () => context.push('/revision'),
                ),
                const SizedBox(height: 8),
                _buildActionTile(
                  context,
                  "Watch Ad → +100 Coins",
                  "Earn bonus coins by watching a short ad",
                  Icons.play_circle_fill,
                  AppColors.accent,
                  () => _watchRewardedAd(context),
                ),
                const SizedBox(height: 24),

                // Achievements
                _buildSectionHeader(context, "Achievements"),
                const SizedBox(height: 12),
                _buildAchievements(context, gamification, progress, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelCard(
      BuildContext context, GamificationNotifier gamification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${gamification.level}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gamification.xpToNextLevel} XP to next level',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: gamification.levelProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.24),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInlineStatBadge(
                      Icons.monetization_on,
                      '${gamification.coins} Coins',
                      AppColors.accent,
                    ),
                    _buildInlineStatBadge(
                      Icons.local_fire_department,
                      '${gamification.streak}d streak',
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, GamificationNotifier gamification) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard(
          context,
          "🔥 Streak",
          "${gamification.streak}",
          "Best: ${gamification.bestStreak}",
          Colors.orange,
        ),
        _buildStatCard(
          context,
          "⭐ Total XP",
          "${gamification.xp}",
          "Level ${gamification.level}",
          AppColors.primary,
        ),
        _buildStatCard(
          context,
          "🕯️ Patterns",
          "${gamification.completedLessons.length}",
          "Completed",
          Colors.purple,
        ),
        _buildStatCard(
          context,
          "📈 Indicators",
          "${gamification.completedIndicators.length}",
          "Completed",
          Colors.teal,
        ),
        _buildStatCard(
          context,
          "🏹 Challenges",
          "${gamification.completedChallenges.length}",
          "Completed",
          Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildInlineStatBadge(IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      String subtitle, Color color) {
    final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(
      BuildContext context,
      GamificationNotifier gamification,
      UserProgressNotifier progress,
      ThemeData theme) {
    final totalPatterns = context.read<PatternsNotifier>().patterns.length;
    final totalIndicators = LessonRepository().getIndicators().length;

    return Column(
      children: [
        _buildAchievementTile(
            context,
            "First Steps",
            "Complete your first lesson.",
            gamification.completedLessons.isNotEmpty),
        _buildAchievementTile(
            context,
            "Dedicated Learner",
            "Learn 10 candlestick patterns.",
            gamification.completedLessons.length >= 10),
        _buildAchievementTile(context, "Streak Starter",
            "Reach a 3-day streak.", gamification.bestStreak >= 3),
        _buildAchievementTile(context, "On Fire", "Reach a 7-day streak.",
            gamification.bestStreak >= 7),
        _buildAchievementTile(context, "Quiz Warrior",
            "Answer 50 quiz questions.", progress.totalQuestions >= 50),
        _buildAchievementTile(
            context,
            "Sharp Eye",
            "Achieve 80%+ quiz accuracy.",
            progress.quizAccuracy >= 80 && progress.totalQuestions >= 5),
        _buildAchievementTile(
            context,
            "Pattern Master",
            "Learn all candlestick patterns.",
            totalPatterns > 0 &&
                gamification.completedLessons.length >= totalPatterns),
        _buildAchievementTile(
            context,
            "Indicator Explorer",
            "Complete 10 indicator lessons.",
            gamification.completedIndicators.length >= 10),
        _buildAchievementTile(
            context,
            "Indicator Specialist",
            "Complete all indicator lessons.",
            totalIndicators > 0 &&
                gamification.completedIndicators.length >= totalIndicators),
        _buildAchievementTile(
            context,
            "Challenge Crusher",
            "Complete 25 practice or daily challenges.",
            gamification.completedChallenges.length >= 25),
        _buildAchievementTile(
            context, "Level 5", "Reach Level 5.", gamification.level >= 5),
        _buildAchievementTile(context, "Coin Collector", "Earn 500 coins.",
            gamification.coins >= 500),
      ],
    );
  }

  Widget _buildAchievementTile(
      BuildContext context, String title, String description, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(unlocked ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock,
            color: unlocked ? AppColors.accent : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: unlocked ? null : Colors.grey)),
                Text(description,
                    style: TextStyle(
                        fontSize: 12,
                        color: unlocked
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : Colors.grey)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Future<void> _watchRewardedAd(BuildContext context) async {
    final result = await AdService.instance.showRewardedAd(
      onRewarded: () {
        context.read<GamificationNotifier>().rewardAdCoins();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🎉 +100 Coins earned!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    if (!context.mounted) return;

    switch (result) {
      case RewardedAdResult.rewarded:
        // Reward already granted inside the callback above.
        break;
      case RewardedAdResult.dismissed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Watch the full ad to earn coins!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case RewardedAdResult.loading:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⏳ Ad is loading… tap again in a moment!"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      case RewardedAdResult.notInitialized:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ad service unavailable. Try again later!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
