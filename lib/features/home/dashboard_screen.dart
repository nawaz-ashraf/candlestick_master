import 'dart:io';

import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/data/repositories/lesson_repository.dart';
import 'package:candlestick_master/models/lesson_model.dart';
import 'package:candlestick_master/models/pattern_model.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

typedef HomeTabChangeCallback = void Function(
  int index, {
  int? learnTabIndex,
});

class DashboardScreen extends StatelessWidget {
  // Callback to switch tabs in the parent HomeScreen
  // Navigation indices: 0=Home, 1=Learn, 2=Quiz, 3=Challenge, 4=Profile
  final HomeTabChangeCallback onTabChange;

  const DashboardScreen({super.key, required this.onTabChange});

  static final LessonRepository _lessonRepository = LessonRepository();

  /// Navigate to pattern detail with interstitial ad
  Future<void> _navigateToPattern(
      BuildContext context, CandlestickPattern pattern) async {
    await AdService.instance.showInterstitialAd();
    if (context.mounted) {
      context.push('/pattern/${pattern.id}', extra: pattern);
    }
  }

  /// Share app logo with marketing text
  Future<void> _shareApp(BuildContext context) async {
    try {
      // Marketing text for sharing
      const String marketingText = '''
🕯️ Master Candlestick Patterns with Candlestick Master!

📈 Learn 40+ candlestick patterns
    📊 Study 25+ indicators with clear explanations
🎯 Practice with interactive quizzes
    🔥 Build streaks with daily lessons and 100+ challenges
📊 Track your learning progress
🌙 Beautiful dark/light mode

Download now and become a trading expert!
https://play.google.com/store/apps/details?id=com.candlestickmaster.app
''';

      // Load the app logo from assets
      final ByteData bytes =
          await rootBundle.load('assets/AppIcons/playstore.png');
      final Uint8List logoBytes = bytes.buffer.asUint8List();

      // Save to temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final logoFile = File('${tempDir.path}/candlestick_master_logo.png');
      await logoFile.writeAsBytes(logoBytes);

      // Share with image
      await Share.shareXFiles(
        [XFile(logoFile.path)],
        text: marketingText,
        subject: 'Check out Candlestick Master!',
      );
    } catch (e) {
      // Fallback to text-only sharing if image fails
      debugPrint('Share with image failed: $e');
      await Share.share(
        '🕯️ Master Candlestick Patterns with Candlestick Master!\n\n'
        '📈 Learn 40+ candlestick patterns\n'
        '🎯 Practice with interactive quizzes\n\n'
        'Download: https://play.google.com/store/apps/details?id=com.candlestickmaster.app',
        subject: 'Check out Candlestick Master!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Candlestick Master",
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          // Gamification quick stats in app bar
          Consumer<GamificationNotifier>(
            builder: (context, gamification, _) {
              return Row(
                children: [
                  _buildMiniStat(Icons.local_fire_department,
                      gamification.streak.toString(), Colors.orange),
                  const SizedBox(width: 8),
                  _buildMiniStat(Icons.monetization_on,
                      gamification.coins.toString(), AppColors.accent),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
          IconButton(
            onPressed: () => _shareApp(context),
            icon: const Icon(Icons.share),
            tooltip: "Share App",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gamification Header
            Consumer2<GamificationNotifier, PatternsNotifier>(
              builder: (context, gamification, patternsNotifier, _) {
                final patternLessons =
                    _lessonRepository.buildCandlestickLessons(
                  patternsNotifier.patterns,
                );
                final indicatorLessons =
                    _lessonRepository.buildIndicatorLessons();

                final allLessons = [...patternLessons, ...indicatorLessons];
                final unlockedLessonIds = _collectUnlockedLessonIds(
                  patternLessons: patternLessons,
                  indicatorLessons: indicatorLessons,
                  gamification: gamification,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context
                      .read<GamificationNotifier>()
                      .ensureDailyLesson(unlockedLessonIds);
                });

                LessonModel? dailyLesson;
                for (final lesson in allLessons) {
                  if (lesson.id == gamification.dailyLessonId) {
                    dailyLesson = lesson;
                    break;
                  }
                }

                return _buildGamifiedHeader(
                  context,
                  gamification,
                  dailyLesson: dailyLesson,
                );
              },
            ),

            const SizedBox(height: 24),

            // Daily Challenge Card
            Consumer<GamificationNotifier>(
              builder: (context, gamification, _) {
                return _buildDailyChallengeCard(context, gamification);
              },
            ),

            const SizedBox(height: 24),

            // Cheatsheet Section
            _buildCheatsheetSection(context),

            const SizedBox(height: 24),

            Text("Quick Access", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              "Pattern Library",
              "Browse patterns and indicators by difficulty",
              Icons.grid_view,
              Colors.purple,
              () => onTabChange(1, learnTabIndex: 0), // Open Learn > Patterns
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Indicator Learning",
              "Understand indicators with visual chart examples",
              Icons.insights,
              AppColors.accent,
              () => onTabChange(1, learnTabIndex: 1), // Open Learn > Indicators
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Challenge Arena",
              "Daily challenge + 100+ practice challenges",
              Icons.local_fire_department,
              Colors.deepOrange,
              () => onTabChange(3), // Switch to Challenge Tab
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Practice Quiz",
              "Test your knowledge with quizzes",
              Icons.quiz,
              Colors.green,
              () => onTabChange(2), // Switch to Quiz Tab
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildGamifiedHeader(
    BuildContext context,
    GamificationNotifier gamification, {
    LessonModel? dailyLesson,
  }) {
    final int targetLearnTab =
        dailyLesson?.type == LearningConstants.moduleIndicator ? 1 : 0;

    return GestureDetector(
      onTap: () => onTabChange(1, learnTabIndex: targetLearnTab),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.82),
              AppColors.primary.withOpacity(0.46),
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
              child: Text(
                'Lv\n${gamification.level}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keep it up!',
                    style: TextStyle(
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
                  if (dailyLesson != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Today: ${dailyLesson.title}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(
      BuildContext context, GamificationNotifier gamification) {
    final bool completed = gamification.isDailyChallengeCompletedToday;

    return GestureDetector(
      onTap: () {
        if (!completed) {
          onTabChange(3); // Go to Challenge tab
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: completed
                ? [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.4)
                  ]
                : [
                    AppColors.accent.withOpacity(0.8),
                    AppColors.accent.withOpacity(0.4)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (completed ? AppColors.primary : AppColors.accent)
                  .withOpacity(0.3),
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
              child: Icon(
                completed ? Icons.check_circle : Icons.star,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daily Challenge",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed
                        ? "Completed! Come back tomorrow."
                        : "Complete 5 questions for +30 XP & +50 Coins!",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!completed)
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// Build the horizontally scrollable cheatsheet section
  Widget _buildCheatsheetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Pattern Cheatsheet",
                style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => onTabChange(1), // Go to Pattern Library
              child: const Text("See All",
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Consumer<PatternsNotifier>(
            builder: (context, notifier, child) {
              if (notifier.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final patterns = notifier.patterns;
              if (patterns.isEmpty) {
                return const Center(
                  child: Text("No patterns available",
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              // Show first 10 patterns for cheatsheet (mix of different types)
              final cheatsheetPatterns = patterns.take(10).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cheatsheetPatterns.length,
                itemBuilder: (context, index) {
                  final pattern = cheatsheetPatterns[index];
                  return _buildCheatsheetCard(context, pattern);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build a single cheatsheet card
  Widget _buildCheatsheetCard(
      BuildContext context, CandlestickPattern pattern) {
    // Determine bias color
    Color biasColor = AppColors.neutral;
    if (pattern.bias == "Bullish") {
      biasColor = AppColors.bullish;
    } else if (pattern.bias == "Bearish") {
      biasColor = AppColors.bearish;
    }

    return GestureDetector(
      onTap: () => _navigateToPattern(context, pattern),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pattern Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: AppColors.surface,
                child: pattern.imagePath.isNotEmpty
                    ? Image.asset(
                        pattern.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(Icons.candlestick_chart,
                              color: AppColors.primary, size: 40),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.candlestick_chart,
                            color: AppColors.primary, size: 40),
                      ),
              ),
            ),
            // Pattern Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Bias Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: biasColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pattern.bias,
                      style: TextStyle(
                        color: biasColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12)),
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

  List<String> _collectUnlockedLessonIds({
    required List<LessonModel> patternLessons,
    required List<LessonModel> indicatorLessons,
    required GamificationNotifier gamification,
  }) {
    final unlocked = <String>{};

    for (final lesson in patternLessons) {
      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      final isUnlocked = gamification.isDifficultyUnlocked(
        module: LearningConstants.modulePattern,
        difficulty: difficulty,
      );
      if (isUnlocked) {
        unlocked.add(lesson.id);
      }
    }

    for (final lesson in indicatorLessons) {
      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      final isUnlocked = gamification.isDifficultyUnlocked(
        module: LearningConstants.moduleIndicator,
        difficulty: difficulty,
      );
      if (isUnlocked) {
        unlocked.add(lesson.id);
      }
    }

    return unlocked.toList(growable: false);
  }
}
