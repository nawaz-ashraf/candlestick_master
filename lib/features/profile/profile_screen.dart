// =============================================================================
// ProfileScreen - Redesigned User Profile & Stats Hub
// =============================================================================
// Displays:
// A. Profile App Bar with theme toggle and drawer menu icon
// B. User Account Header at the top
// C. Learning Progress Card (Level, XP, progress bar, streaks, coins)
// D. Learning Statistics (Patterns, Indicators, Challenges completed)
// E. Account Actions (Sign Out, Delete Account - NO Sync Now button)
// F. Quick Actions (Practice Mistakes, Watch Ad)
// G. Achievements
// =============================================================================

import "package:candlestick_master/core/constants/reward_constants.dart";
import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/data/repositories/lesson_repository.dart";
import "package:candlestick_master/providers/auth_notifier.dart";
import "package:candlestick_master/providers/gamification_notifier.dart";
import "package:candlestick_master/providers/pattern_notifier.dart";
import "package:candlestick_master/providers/theme_notifier.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:candlestick_master/providers/user_progress_notifier.dart";
import "package:candlestick_master/widgets/rewarded_ad_bottom_sheet.dart";
import "package:in_app_review/in_app_review.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ProfileScreen({super.key, this.onOpenDrawer});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    // Automatic background cloud sync on viewing profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final auth = context.read<AuthNotifier>();
        if (auth.isAuthenticated) {
          final gamification = context.read<GamificationNotifier>();
          final tradeNotifier = context.read<TradeNotifier>();
          final userProgress = context.read<UserProgressNotifier>();
          auth.syncOnLogin(
            gamification,
            tradeNotifier: tradeNotifier,
            userProgress: userProgress,
          );
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ==========================================
      // A. PROFILE APP BAR
      // ==========================================
      appBar: AppBar(
        title: const Text("Profile"),
        automaticallyImplyLeading: false,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: "Open Navigation Menu",
                onPressed: widget.onOpenDrawer,
              )
            : null,
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
      body: Consumer3<GamificationNotifier, UserProgressNotifier, AuthNotifier>(
        builder: (context, gamification, progress, auth, _) {
          return SingleChildScrollView(
            // Bottom padding ensures banner ad never covers bottom actions
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. ACCOUNT SETTINGS (User info, Sign Out & Delete Account)
                // ==========================================
                _buildAccountSettings(context, auth),
                const SizedBox(height: 18),

                // ==========================================
                // 2. LEARNING PROGRESS CARD
                // ==========================================
                _buildLearningProgressCard(context, gamification),
                const SizedBox(height: 18),

                // ==========================================
                // 3. LEARNING STATISTICS
                // ==========================================
                _buildLearningStatistics(context, gamification),
                const SizedBox(height: 20),

                // ==========================================
                // 4. REVIEW & SHARE ACTIONS
                // ==========================================
                _buildActionTile(
                  context,
                  "Write a Review",
                  "Enjoying Candlestick Master? Rate us on Google Play.",
                  Icons.star_rounded,
                  AppColors.accent,
                  () => _handleWriteReview(context),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  context,
                  "Share App",
                  "Invite friends to learn candlestick patterns and trading indicators.",
                  Icons.share_rounded,
                  AppColors.primary,
                  () => _handleShareApp(context),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  context,
                  "Privacy Policy",
                  "Learn how we collect, use, and protect your data.",
                  Icons.privacy_tip_outlined,
                  AppColors.primarySoft,
                  () => context.push("/privacy-policy"),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  context,
                  "Terms of Service",
                  "Read the terms and conditions for using the app.",
                  Icons.description_outlined,
                  AppColors.accent,
                  () => context.push("/terms-of-service"),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 5. QUICK ACTIONS
                // ==========================================
                _buildSectionHeader(context, "Quick Actions"),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  "Practice Mistakes",
                  "${gamification.wrongAnswers.length} questions to review",
                  Icons.replay_circle_filled,
                  AppColors.bearish,
                  () => context.push("/revision"),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  context,
                  "Watch Ad → +100 Coins",
                  "Earn bonus coins by watching a short ad",
                  Icons.play_circle_fill,
                  AppColors.accent,
                  () => _watchRewardedAd(context),
                ),
                const SizedBox(height: 26),

                // ==========================================
                // 6. ACHIEVEMENTS
                // ==========================================
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

  // ===========================================================================
  // C. Learning Progress Card
  // ===========================================================================
  Widget _buildLearningProgressCard(
      BuildContext context, GamificationNotifier gamification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            const Color(0xFF00966B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Level ${gamification.level}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${gamification.xpToNextLevel} XP to next level • ${gamification.xp} Total XP",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: gamification.levelProgress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          // Badges: Coins, Streak, Best Streak
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInlineBadge(
                Icons.monetization_on_rounded,
                "${gamification.coins} Coins",
                AppColors.accent,
              ),
              _buildInlineBadge(
                Icons.local_fire_department_rounded,
                "${gamification.streak}d streak",
                Colors.orangeAccent,
              ),
              _buildInlineBadge(
                Icons.star_rounded,
                "Best: ${gamification.bestStreak}d",
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineBadge(IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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

  // ===========================================================================
  // D. Learning Statistics (Compact responsive 3-card grid)
  // ===========================================================================
  Widget _buildLearningStatistics(
      BuildContext context, GamificationNotifier gamification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Learning Statistics"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                context,
                title: "Patterns",
                value: "${gamification.completedLessons.length}",
                subtitle: "Completed",
                icon: Icons.candlestick_chart_rounded,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                context,
                title: "Indicators",
                value: "${gamification.completedIndicators.length}",
                subtitle: "Completed",
                icon: Icons.insights_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                context,
                title: "Challenges",
                value: "${gamification.completedChallenges.length}",
                subtitle: "Completed",
                icon: Icons.military_tech_rounded,
                color: Colors.deepOrangeAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Account Settings (with Sign Out, Delete Account, or Sign In for Guests)
  // ===========================================================================
  Widget _buildAccountSettings(BuildContext context, AuthNotifier auth) {
    if (auth.isAuthenticated) {
      final user = auth.user;
      final email = user?.email ?? "";
      String displayName = user?.displayName ?? "";
      if (displayName.trim().isEmpty && email.isNotEmpty) {
        final prefix = email.split("@").first;
        displayName = prefix[0].toUpperCase() + prefix.substring(1);
      }
      if (displayName.trim().isEmpty) {
        displayName = "Trader";
      }

      final initial = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : (email.isNotEmpty ? email[0].toUpperCase() : "T");

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Account Settings",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            // User identity row
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00B074),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bullish.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.bullish,
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: AppColors.bullish),
                      SizedBox(width: 4),
                      Text(
                        "Active",
                        style: TextStyle(
                          color: AppColors.bullish,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),
            // Sign Out Button
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, auth),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                "Sign Out",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            // Delete Account Button (clearly separated destructive action)
            Center(
              child: TextButton(
                onPressed: () => _confirmDeleteAccount(context, auth),
                child: const Text(
                  "Delete Account & Data",
                  style: TextStyle(
                    color: AppColors.bearish,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Account Settings",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Guest Trader",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        "Sign in to backup your XP, streaks & journal",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.push("/login"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Sign In / Create Account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, AuthNotifier auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Sign Out?",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          "Are you sure you want to sign out? Your progress remains safely stored in your cloud account.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final gamification = context.read<GamificationNotifier>();
      final tradeNotifier = context.read<TradeNotifier>();
      final userProgress = context.read<UserProgressNotifier>();
      await auth.signOut(
        gamification: gamification,
        tradeNotifier: tradeNotifier,
        userProgress: userProgress,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signed out successfully")),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AuthNotifier auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Delete Account & Data?",
          style: TextStyle(color: AppColors.bearish),
        ),
        content: const Text(
          "This action is permanent and cannot be undone. All your synchronized cloud data, XP, streaks, and journal records will be deleted.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              "Delete Account",
              style: TextStyle(color: AppColors.bearish, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final gamification = context.read<GamificationNotifier>();
      final tradeNotifier = context.read<TradeNotifier>();
      final userProgress = context.read<UserProgressNotifier>();
      final success = await auth.deleteAccount(
        gamification: gamification,
        tradeNotifier: tradeNotifier,
        userProgress: userProgress,
      );
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account and cloud data deleted")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? "Failed to delete account"),
              backgroundColor: AppColors.bearish,
            ),
          );
        }
      }
    }
  }

  // ===========================================================================
  // Review & Share Flow Handlers
  // ===========================================================================
  Future<void> _handleWriteReview(BuildContext context) async {
    const playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.candlestickmaster.app";
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        return;
      }
    } catch (e) {
      debugPrint("InAppReview error: $e");
    }

    final uri = Uri.parse(playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch Play Store URL";
      }
    } catch (e) {
      debugPrint("Play Store launch error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open Google Play Store right now."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleShareApp(BuildContext context) async {
    const shareMessage =
        "Learn candlestick patterns, explore trading indicators, and practice with quizzes using Candlestick Master.\n\n"
        "Download the app:\n"
        "https://play.google.com/store/apps/details?id=com.candlestickmaster.app";
    try {
      await Share.share(
        shareMessage,
        subject: "Learn Trading with Candlestick Master",
      );
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  // ===========================================================================
  // F. Quick Actions & Helpers
  // ===========================================================================
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // G. Achievements
  // ===========================================================================
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.divider.withOpacity(0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? AppColors.accent : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }

  Future<void> _watchRewardedAd(BuildContext context) async {
    if (_isWatchingAd) return;
    _isWatchingAd = true;

    try {
      final gamification = context.read<GamificationNotifier>();
      final result = await RewardedAdBottomSheet.show(
        context,
        title: "Earn Bonus Coins",
        description: "Watch a short ad to earn bonus coins!",
        rewardAmount: RewardConstants.rewardedAdCoins,
        onRewardEarned: () async {
          await gamification.rewardAdCoins();
        },
      );

      if (!context.mounted) return;

      switch (result) {
        case RewardedFlowResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🎉 +100 Coins earned!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        case RewardedFlowResult.fallback:
        case RewardedFlowResult.cancelled:
          break;
      }
    } finally {
      _isWatchingAd = false;
    }
  }
}
