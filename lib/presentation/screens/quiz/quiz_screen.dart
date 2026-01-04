// =============================================================================
// QuizScreen - Practice Quiz Mode
// =============================================================================
// Tests user knowledge of candlestick patterns with multiple choice questions.
// Features:
// - Progress tracking
// - Score display
// - Explanation after each answer
// - Interstitial ad BEFORE quiz starts (high-intent moment, per requirements)
// - NO ads during quiz or at completion (to preserve learning experience)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/quiz_notifier.dart';
import '../../providers/pattern_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

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
        await context.read<QuizNotifier>().startQuiz(patterns);
        setState(() => _quizStarted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Practice Quiz")),
      body: Consumer<QuizNotifier>(
        builder: (context, notifier, _) {
          // Show loading while ad is being shown or quiz is starting
          if (notifier.isLoading || !_quizStarted) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Preparing quiz...", style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          
          if (notifier.questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text("No questions available."),
                  const SizedBox(height: 8),
                  const Text("Ensure patterns are loaded.", style: TextStyle(color: AppColors.textSecondary)),
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
            // NO ad at completion - preserves the learning experience
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Quiz Finished!",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Score: ${notifier.score}/${notifier.questions.length}",
                    style: const TextStyle(fontSize: 18, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.home),
                    label: const Text("Exit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
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
                    value: (notifier.currentIndex + 1) / notifier.questions.length,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    "Question ${notifier.currentIndex + 1}/${notifier.questions.length}",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image if available
                  if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        question.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Options - NO ads during quiz
                  ...List.generate(question.options.length, (index) {
                    final isSelected = notifier.selectedOption == index;
                    final isCorrect = index == question.correctOptionIndex;
                    
                    Color color = AppColors.surface;
                    if (notifier.answered) {
                      if (isCorrect) {
                        color = AppColors.bullish;
                      } else if (isSelected && !isCorrect) {
                        color = AppColors.bearish;
                      }
                    } else if (isSelected) {
                      color = AppColors.primary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: notifier.answered ? null : () async {
                           await notifier.submitAnswer(index);
                           Future.delayed(const Duration(seconds: 2), () {
                             if(context.mounted) notifier.nextQuestion();
                           });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent
                            ),
                          ),
                          child: Text(
                            question.options[index],
                            style: const TextStyle(fontSize: 16),
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
                        style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
}
