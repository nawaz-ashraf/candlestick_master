import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_notifier.dart';
import '../../providers/user_progress_notifier.dart';
import '../../providers/pattern_notifier.dart';
import '../../../core/theme/app_theme.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Progress"),
        actions: [
          // Theme Toggle Switch
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeNotifier.toggleTheme(!themeNotifier.isDarkMode);
                },
                tooltip: "Toggle Theme",
              );
            },
          ),
        ],
      ),
      body: Consumer2<UserProgressNotifier, PatternsNotifier>(
        builder: (context, progressNotifier, patternsNotifier, child) {
          final learnedCount = progressNotifier.learnedCount;
          final totalPatterns = patternsNotifier.patterns.length;
          final quizAccuracy = progressNotifier.quizAccuracy;
          final totalQuestions = progressNotifier.totalQuestions;
          final correctAnswers = progressNotifier.correctAnswers;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Learning Streak Section
                _buildSectionHeader(context, "Learning Streak"),
                const SizedBox(height: 12),
                _buildStreakCard(context, learnedCount),

                const SizedBox(height: 24),

                // Stats Grid
                _buildSectionHeader(context, "Statistics"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        "Patterns Learned",
                        "$learnedCount${totalPatterns > 0 ? '/$totalPatterns' : ''}",
                        Icons.grid_view,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        "Quiz Accuracy",
                        totalQuestions > 0
                            ? "${quizAccuracy.toStringAsFixed(0)}%"
                            : "N/A",
                        Icons.quiz,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Second row of stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        "Questions Answered",
                        "$totalQuestions",
                        Icons.help_outline,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        "Correct Answers",
                        "$correctAnswers",
                        Icons.check_circle_outline,
                        AppColors.bullish,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Achievements Section
                _buildSectionHeader(context, "Achievements"),
                const SizedBox(height: 12),
                _buildAchievementTile(
                  context,
                  "First Steps",
                  "Completed your first candlestick pattern tutorial.",
                  learnedCount >= 1,
                ),
                _buildAchievementTile(
                  context,
                  "Dedicated Learner",
                  "Learned 10 candlestick patterns.",
                  learnedCount >= 10,
                ),
                _buildAchievementTile(
                  context,
                  "Sharp Eye",
                  "Achieved 80% or higher quiz accuracy.",
                  quizAccuracy >= 80 && totalQuestions >= 5,
                ),
                _buildAchievementTile(
                  context,
                  "Quiz Master",
                  "Answered 50 quiz questions.",
                  totalQuestions >= 50,
                ),
                _buildAchievementTile(
                  context,
                  "Pattern Expert",
                  "Learned all candlestick patterns.",
                  totalPatterns > 0 && learnedCount >= totalPatterns,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int learnedCount) {
    // Determine streak message based on progress
    String streakTitle;
    String streakSubtitle;
    IconData streakIcon;

    if (learnedCount == 0) {
      streakTitle = "Start Learning!";
      streakSubtitle = "Mark your first pattern as learned to begin.";
      streakIcon = Icons.lightbulb_outline;
    } else if (learnedCount < 5) {
      streakTitle = "Getting Started!";
      streakSubtitle =
          "You've learned $learnedCount pattern${learnedCount == 1 ? '' : 's'}. Keep it up!";
      streakIcon = Icons.trending_up;
    } else if (learnedCount < 15) {
      streakTitle = "Making Progress!";
      streakSubtitle = "Great job! $learnedCount patterns learned.";
      streakIcon = Icons.local_fire_department;
    } else {
      streakTitle = "On Fire! 🔥";
      streakSubtitle = "Amazing! You've mastered $learnedCount patterns!";
      streakIcon = Icons.emoji_events;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(streakIcon, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          Text(
            streakTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streakSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(
      BuildContext context, String title, String description, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: unlocked
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
