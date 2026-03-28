// =============================================================================
// DailyChallengeScreen - 5 Daily Questions with Rewards
// =============================================================================
// Provides 5 random quiz questions per day (deterministic by date seed).
// Awards +30 XP and +50 coins on completion.
// Shows "Completed" state if already done today.
// =============================================================================

import 'dart:math';

import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/domain/logic/quiz_generator.dart';
import 'package:candlestick_master/models/quiz_question.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyChallengeScreen extends StatefulWidget {
  final bool showAppBar;

  const DailyChallengeScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final QuizGenerator _generator = QuizGenerator();
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOption;
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChallenge());
  }

  Future<void> _loadChallenge() async {
    final patterns = context.read<PatternsNotifier>().patterns;
    if (patterns.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Generate 5 questions with date-based seed for deterministic daily set
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(dateSeed);

    // Shuffle patterns with date seed and pick 5
    final shuffled = List.of(patterns)..shuffle(random);
    final selected = shuffled.take(5).toList();

    _questions = await _generator.generateMixedQuiz(
      selected,
      count: 5,
    );

    setState(() => _isLoading = false);
  }

  void _submitAnswer(int optionIndex) {
    if (_answered) return;

    final question = _questions[_currentIndex];
    final isCorrect = optionIndex == question.correctOptionIndex;

    if (isCorrect) _score++;

    // Track in gamification
    final gamification = context.read<GamificationNotifier>();
    gamification.recordChallengeAnswer(question.correctPattern.id, isCorrect);

    setState(() {
      _answered = true;
      _selectedOption = optionIndex;
    });

    // Auto-advance after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedOption = null;
        });
      } else {
        // Challenge complete
        _completeChallenge();
      }
    });
  }

  Future<void> _completeChallenge() async {
    final gamification = context.read<GamificationNotifier>();
    await gamification.completeDailyChallenge();
    setState(() => _isFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text("Daily Challenge"),
              automaticallyImplyLeading: false,
            )
          : null,
      body: Consumer<GamificationNotifier>(
        builder: (context, gamification, _) {
          // Already completed today
          if (gamification.isDailyChallengeCompletedToday && !_isFinished) {
            return _buildCompletedState(theme, colorScheme);
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz,
                      size: 64, color: colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text("No questions available.",
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          if (_isFinished) {
            return _buildResultScreen(theme, colorScheme);
          }

          return _buildQuestionView(theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildCompletedState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primarySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child:
                  const Icon(Icons.check_circle, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              "Challenge Completed!",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You've already completed today's challenge.\nCome back tomorrow for a new one!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    "+30 XP  •  +50 Coins",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
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

  Widget _buildQuestionView(ThemeData theme, ColorScheme colorScheme) {
    final question = _questions[_currentIndex];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Challenge Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.2),
                    AppColors.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Daily Challenge",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          "Question ${_currentIndex + 1} of ${_questions.length}",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        "$_score/${_currentIndex + (_answered ? 1 : 0)}",
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
            const SizedBox(height: 24),

            // Question text
            Text(
              question.questionText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  question.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),

            const SizedBox(height: 24),

            // Options
            ...List.generate(question.options.length, (index) {
              final isSelected = _selectedOption == index;
              final isCorrect = index == question.correctOptionIndex;

              Color backgroundColor = colorScheme.surface;
              Color textColor = colorScheme.onSurface;

              if (_answered) {
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
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _answered ? null : () => _submitAnswer(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected && !_answered
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      question.options[index],
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ),
                ),
              );
            }),

            // Explanation
            if (_answered)
              Padding(
                padding: const EdgeInsets.only(top: 16),
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
  }

  Widget _buildResultScreen(ThemeData theme, ColorScheme colorScheme) {
    final isPerfect = _score == _questions.length;
    final accuracy =
        _questions.isNotEmpty ? (_score / _questions.length * 100) : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Trophy
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPerfect
                      ? [AppColors.accent, const Color(0xFFF4C430)]
                      : [AppColors.primary, AppColors.primarySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events : Icons.celebration,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              isPerfect ? "Perfect Challenge! 🏆" : "Challenge Complete!",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // Stats card
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
                      _buildStatColumn("Score", "$_score/${_questions.length}",
                          colorScheme.primary, theme),
                      Container(
                          width: 1,
                          height: 50,
                          color: colorScheme.outline.withOpacity(0.2)),
                      _buildStatColumn(
                          "Accuracy",
                          "${accuracy.toStringAsFixed(0)}%",
                          AppColors.accent,
                          theme),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Rewards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRewardChip("+30 XP", Icons.star, AppColors.primary),
                      const SizedBox(width: 16),
                      _buildRewardChip(
                          "+50 Coins", Icons.monetization_on, AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Come back tomorrow for a new challenge!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            )),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
      ],
    );
  }

  Widget _buildRewardChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
