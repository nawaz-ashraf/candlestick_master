// =============================================================================
// QuizScreen - Practice Quiz Mode
// =============================================================================
// Tests user knowledge of candlestick patterns with multiple choice questions.
// Features:
// - Progress tracking
// - Score display
// - Explanation after each answer
// - Theme-aware styling (respects light/dark mode)
// - Enhanced result screen with accuracy and restart option
// - Interstitial ad BEFORE quiz starts (high-intent moment, per requirements)
// - NO ads during quiz or at completion (to preserve learning experience)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/quiz_notifier.dart';
import '../../providers/pattern_notifier.dart';
import '../../providers/user_progress_notifier.dart';
import '../../../data/models/quiz_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';

class QuizScreen extends StatefulWidget {
  final QuizSettings? settings;

  const QuizScreen({super.key, this.settings});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Track if we've shown the pre-quiz interstitial ad
  bool _hasShownPreQuizAd = false;
  bool _quizStarted = false;

  @override
  void initState() {
    super.initState();
    // Show ad and start quiz after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showPreQuizAdAndStart();
    });
  }

  /// Show interstitial ad BEFORE quiz starts (high-intent moment)
  /// This is the ideal placement as user is committed to taking the quiz
  Future<void> _showPreQuizAdAndStart() async {
    if (!_hasShownPreQuizAd) {
      _hasShownPreQuizAd = true;

      // Show interstitial ad (non-blocking - continues even if ad fails)
      await AdService.instance.forceShowInterstitialAd();

      // Start the quiz after ad
      if (mounted) {
        final patterns = context.read<PatternsNotifier>().patterns;
        await context.read<QuizNotifier>().startQuiz(
              patterns,
              settings: widget.settings,
            );
        setState(() => _quizStarted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Practice Quiz")),
      body: Consumer<QuizNotifier>(
        builder: (context, notifier, _) {
          // Show loading while ad is being shown or quiz is starting
          if (notifier.isLoading || !_quizStarted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Preparing quiz...",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (notifier.questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No questions available.",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ensure patterns are loaded.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            );
          }

          if (notifier.isFinished) {
            // Enhanced result screen with accuracy and restart option
            return _buildResultScreen(context, notifier, theme, colorScheme);
          }

          final question = notifier.currentQuestion;
          if (question == null) return const SizedBox();

          // Using ClampingScrollPhysics to prevent _StretchController assertion
          // errors on Android when content changes dynamically
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress
                  LinearProgressIndicator(
                    value:
                        (notifier.currentIndex + 1) / notifier.questions.length,
                    backgroundColor: colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Question ${notifier.currentIndex + 1}/${notifier.questions.length}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.questionText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image if available
                  if (question.imageUrl != null &&
                      question.imageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        question.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) => const Center(
                            child: Icon(Icons.image_not_supported)),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Options - NO ads during quiz
                  ...List.generate(question.options.length, (index) {
                    final isSelected = notifier.selectedOption == index;
                    final isCorrect = index == question.correctOptionIndex;

                    Color backgroundColor = colorScheme.surface;
                    Color textColor = colorScheme.onSurface;

                    if (notifier.answered) {
                      if (isCorrect) {
                        backgroundColor = AppColors.bullish;
                        textColor = Colors.white;
                      } else if (isSelected && !isCorrect) {
                        backgroundColor = AppColors.bearish;
                        textColor = Colors.white;
                      }
                    } else if (isSelected) {
                      backgroundColor = colorScheme.primary;
                      textColor = colorScheme.onPrimary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: notifier.answered
                            ? null
                            : () async {
                                final isCorrect =
                                    index == question.correctOptionIndex;

                                // Record result in UserProgressNotifier for Performance screen
                                context
                                    .read<UserProgressNotifier>()
                                    .recordQuizResult(isCorrect: isCorrect);

                                await notifier.submitAnswer(index);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (context.mounted) notifier.nextQuestion();
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isSelected && !notifier.answered
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2),
                          ),
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  if (notifier.answered)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        question.explanation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen(
    BuildContext context,
    QuizNotifier notifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final accuracy = notifier.accuracy;
    final isPerfect = notifier.score == notifier.questions.length;
    final isGood = accuracy >= 70;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Celebratory Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPerfect
                      ? [const Color(0xFF00C896), const Color(0xFF00E0A4)]
                      : isGood
                          ? [const Color(0xFFE6B566), const Color(0xFFF4C430)]
                          : [colorScheme.primary, colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                isPerfect
                    ? Icons.emoji_events
                    : isGood
                        ? Icons.celebration
                        : Icons.school,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              isPerfect
                  ? "Perfect Score!"
                  : isGood
                      ? "Well Done!"
                      : "Quiz Completed!",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Difficulty Badge
            if (notifier.currentSettings != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${notifier.currentSettings!.difficultyLabel} Mode',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Score
                      Column(
                        children: [
                          Text(
                            'Score',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${notifier.score}/${notifier.questions.length}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 50,
                        color: colorScheme.outline.withOpacity(0.2),
                      ),

                      // Accuracy
                      Column(
                        children: [
                          Text(
                            'Accuracy',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${accuracy.toStringAsFixed(0)}%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPerfect
                                  ? AppColors.bullish
                                  : isGood
                                      ? AppColors.accent
                                      : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Encouraging message
            Text(
              isPerfect
                  ? "Incredible! You've mastered these patterns!"
                  : isGood
                      ? "Great job! Keep practicing to improve further."
                      : "Every quiz makes you better. Try again!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                // Quiz Again Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await notifier.restartQuiz();
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text("Quiz Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Exit Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text("Exit"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
