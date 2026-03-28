// =============================================================================
// RevisionScreen - Practice Mistakes
// =============================================================================
// Shows quiz questions for patterns the user previously got wrong.
// On correct retry, removes the pattern from wrongAnswers.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/models/quiz_question.dart';
import 'package:candlestick_master/domain/logic/quiz_generator.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRevisionQuestions());
  }

  Future<void> _loadRevisionQuestions() async {
    final gamification = context.read<GamificationNotifier>();
    final patternsNotifier = context.read<PatternsNotifier>();
    final wrongPatternIds = gamification.wrongAnswers;

    if (wrongPatternIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Filter patterns that are in wrong answers
    final wrongPatterns = patternsNotifier.patterns
        .where((p) => wrongPatternIds.contains(p.id))
        .toList();

    if (wrongPatterns.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _questions = await _generator.generateMixedQuiz(
      wrongPatterns,
      count: wrongPatterns.length.clamp(1, 10),
    );

    setState(() => _isLoading = false);
  }

  void _submitAnswer(int optionIndex) {
    if (_answered) return;

    final question = _questions[_currentIndex];
    final isCorrect = optionIndex == question.correctOptionIndex;

    if (isCorrect) {
      _score++;
      // Remove from wrong answers on correct retry
      context
          .read<GamificationNotifier>()
          .removeFromWrongAnswers(question.correctPattern.id);
    }

    setState(() {
      _answered = true;
      _selectedOption = optionIndex;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedOption = null;
        });
      } else {
        setState(() => _isFinished = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Practice Mistakes")),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.check_circle,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text("No Mistakes to Review!",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 12),
              Text(
                "You haven't gotten any questions wrong yet,\nor you've corrected all your mistakes. Great job!",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultScreen(theme, colorScheme);
    }

    return _buildQuestionView(theme, colorScheme);
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
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bearish.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.replay, color: AppColors.bearish),
                  const SizedBox(width: 8),
                  Text(
                    "Review ${_currentIndex + 1} of ${_questions.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.bearish),
            ),
            const SizedBox(height: 24),

            Text(question.questionText,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(question.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (c, o, s) =>
                        const Center(child: Icon(Icons.image_not_supported))),
              ),

            const SizedBox(height: 24),

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
                    ),
                    child: Text(question.options[index],
                        style: TextStyle(fontSize: 16, color: textColor)),
                  ),
                ),
              );
            }),

            if (_answered)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(question.explanation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(ThemeData theme, ColorScheme colorScheme) {
    final accuracy = _questions.isNotEmpty
        ? (_score / _questions.length * 100)
        : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Icon(Icons.school, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text("Revision Complete!",
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Score: $_score/${_questions.length}  •  ${accuracy.toStringAsFixed(0)}%",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                )),
            const SizedBox(height: 8),
            Text(
              "$_score mistakes corrected and removed from review!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
