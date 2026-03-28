import 'package:candlestick_master/core/constants/reward_constants.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/models/pattern_model.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LessonSessionScreen extends StatefulWidget {
  final int? startIndex;

  const LessonSessionScreen({super.key, this.startIndex});

  @override
  State<LessonSessionScreen> createState() => _LessonSessionScreenState();
}

class _LessonSessionScreenState extends State<LessonSessionScreen> {
  bool _isLoading = true;
  List<CandlestickPattern> _lessons = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLessons());
  }

  Future<void> _loadLessons() async {
    final patternsNotifier = context.read<PatternsNotifier>();

    if (patternsNotifier.patterns.isEmpty) {
      await patternsNotifier.loadPatterns();
    }

    final allPatterns = patternsNotifier.patterns;
    final lessonPatterns = allPatterns
        .where((pattern) => pattern.category != 'General')
        .toList(growable: false);

    if (!mounted) return;

    final completedIds =
        context.read<GamificationNotifier>().completedLessons.toSet();

    int defaultIndex = lessonPatterns.indexWhere(
      (pattern) => !completedIds.contains(pattern.id),
    );

    if (defaultIndex < 0) {
      defaultIndex = 0;
    }

    if (widget.startIndex != null &&
        widget.startIndex! >= 0 &&
        widget.startIndex! < lessonPatterns.length) {
      defaultIndex = widget.startIndex!;
    }

    setState(() {
      _lessons = lessonPatterns;
      _currentIndex = defaultIndex;
      _isLoading = false;
    });
  }

  Future<void> _completeCurrentLessonAndNext() async {
    if (_lessons.isEmpty) return;

    final currentLesson = _lessons[_currentIndex];
    final gamification = context.read<GamificationNotifier>();
    final progress = context.read<UserProgressNotifier>();

    final wasCompleted = gamification.isLessonCompleted(currentLesson.id);

    await gamification.completeLesson(currentLesson.id);
    await progress.markAsLearned(currentLesson.id);

    if (!mounted) return;

    final message = wasCompleted
        ? 'Lesson reviewed. Streak updated for today.'
        : 'Lesson completed! +${RewardConstants.lessonXp} XP';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (_currentIndex < _lessons.length - 1) {
      setState(() => _currentIndex += 1);
      return;
    }

    await _showSessionCompleteDialog();
  }

  Future<void> _showSessionCompleteDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Lesson Session Complete'),
          content: const Text(
            'Great momentum. Continue with a quiz to reinforce what you learned.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text('Back Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  context.pushReplacement('/quiz/select');
                }
              },
              child: const Text('Start Quiz'),
            ),
          ],
        );
      },
    );
  }

  List<String> _lessonBullets(CandlestickPattern pattern) {
    final keyRuleBullets = pattern.keyRules
        .map((rule) => rule.replaceAll('\n', ' ').trim())
        .where((rule) => rule.isNotEmpty)
        .toList();

    if (keyRuleBullets.length >= 3) {
      return keyRuleBullets.take(4).toList(growable: false);
    }

    final descriptionBullets = pattern.description
        .replaceAll('\n', ' ')
        .split('.')
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.length > 10)
        .toList();

    final combined = [...keyRuleBullets, ...descriptionBullets]
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList();

    if (combined.isEmpty) {
      return const ['Review the candlestick structure before continuing.'];
    }

    return combined.take(4).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Flow'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? _buildEmptyState(theme)
              : _buildLessonView(theme, colorScheme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No lessons available right now.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonView(ThemeData theme, ColorScheme colorScheme) {
    final lesson = _lessons[_currentIndex];
    final bullets = _lessonBullets(lesson);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lesson ${_currentIndex + 1} of ${_lessons.length}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _lessons.length,
            backgroundColor: colorScheme.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson.imagePath.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      lesson.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  lesson.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${lesson.bias} • ${lesson.difficulty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bullet,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentIndex -= 1),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _completeCurrentLessonAndNext,
                  child: Text(
                    _currentIndex == _lessons.length - 1 ? 'Finish' : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
