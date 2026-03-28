import 'dart:math' as math;

import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/data/repositories/lesson_repository.dart';
import 'package:candlestick_master/models/indicator_model.dart';
import 'package:candlestick_master/models/lesson_model.dart';
import 'package:candlestick_master/models/pattern_model.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PatternLibraryScreen extends StatefulWidget {
  final int initialTabIndex;

  const PatternLibraryScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<PatternLibraryScreen> createState() => _PatternLibraryScreenState();
}

class _PatternLibraryScreenState extends State<PatternLibraryScreen>
    with SingleTickerProviderStateMixin {
  final LessonRepository _lessonRepository = LessonRepository();
  ContentDifficulty _selectedDifficulty = ContentDifficulty.basic;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1).toInt(),
    );
  }

  @override
  void didUpdateWidget(covariant PatternLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        nextIndex != _tabController.index) {
      _tabController.animateTo(nextIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider.withOpacity(0.75)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.candlestick_chart, size: 16),
                        SizedBox(width: 6),
                        Text('Patterns'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insights, size: 16),
                        SizedBox(width: 6),
                        Text('Indicators'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer2<PatternsNotifier, GamificationNotifier>(
        builder: (context, patternNotifier, gamification, _) {
          if (patternNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (patternNotifier.error != null) {
            return _buildErrorState(patternNotifier.error!);
          }

          final patterns = patternNotifier.patterns;
          if (patterns.isEmpty) {
            return _buildEmptyState(patternNotifier);
          }

          final patternLessons =
              _lessonRepository.buildCandlestickLessons(patterns);
          final indicatorLessons = _lessonRepository.buildIndicatorLessons();
          final indicatorsById = {
            for (final indicator in _lessonRepository.getIndicators())
              indicator.id: indicator,
          };

          final patternById = {
            for (final pattern in patterns) pattern.id: pattern
          };
          final patternByTitle = {
            for (final pattern in patterns) _normalize(pattern.name): pattern,
          };

          final patternTotals = _difficultyTotals(patternLessons);
          final patternCompleted = _patternCompletionByDifficulty(
            lessons: patternLessons,
            gamification: gamification,
            patternByTitle: patternByTitle,
          );

          final indicatorTotals = _difficultyTotals(indicatorLessons);
          final indicatorCompleted = _indicatorCompletionByDifficulty(
            lessons: indicatorLessons,
            gamification: gamification,
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            final notifier = context.read<GamificationNotifier>();
            notifier.syncUnlockedDifficulties(
              module: LearningConstants.modulePattern,
              completedByDifficulty: patternCompleted,
              totalByDifficulty: patternTotals,
            );
            notifier.syncUnlockedDifficulties(
              module: LearningConstants.moduleIndicator,
              completedByDifficulty: indicatorCompleted,
              totalByDifficulty: indicatorTotals,
            );

            final unlockedLessonIds = _collectUnlockedLessonIds(
              patternLessons: patternLessons,
              indicatorLessons: indicatorLessons,
              gamification: notifier,
            );
            notifier.ensureDailyLesson(unlockedLessonIds);
          });

          final dailyLesson = _resolveDailyLesson(
            dailyLessonId: gamification.dailyLessonId,
            patternLessons: patternLessons,
            indicatorLessons: indicatorLessons,
          );

          return Column(
            children: [
              if (dailyLesson != null)
                _buildDailyLessonBanner(
                  context,
                  dailyLesson,
                  patternById,
                  patternByTitle,
                  indicatorsById,
                  gamification,
                ),
              _buildDifficultySelector(
                context,
                gamification,
                patternTotals,
                patternCompleted,
                indicatorTotals,
                indicatorCompleted,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPatternTab(
                      context: context,
                      lessons: patternLessons,
                      gamification: gamification,
                      patternById: patternById,
                      patternByTitle: patternByTitle,
                    ),
                    _buildIndicatorTab(
                      context: context,
                      lessons: indicatorLessons,
                      gamification: gamification,
                      indicatorsById: indicatorsById,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.bearish),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<PatternsNotifier>().reloadPatterns(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PatternsNotifier patternNotifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No lessons available yet.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: patternNotifier.reloadPatterns,
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLessonBanner(
    BuildContext context,
    LessonModel dailyLesson,
    Map<String, CandlestickPattern> patternById,
    Map<String, CandlestickPattern> patternByTitle,
    Map<String, IndicatorModel> indicatorsById,
    GamificationNotifier gamification,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.9),
            AppColors.accent.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Lesson',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dailyLesson.title,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _openLesson(
              context: context,
              lesson: dailyLesson,
              patternById: patternById,
              patternByTitle: patternByTitle,
              indicatorsById: indicatorsById,
              gamification: gamification,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(
    BuildContext context,
    GamificationNotifier gamification,
    Map<ContentDifficulty, int> patternTotals,
    Map<ContentDifficulty, int> patternCompleted,
    Map<ContentDifficulty, int> indicatorTotals,
    Map<ContentDifficulty, int> indicatorCompleted,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.8)),
      ),
      child: SizedBox(
        height: 62,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          children: LearningConstants.difficultyOrder.map((difficulty) {
            final isSelected = difficulty == _selectedDifficulty;

            final patternsDone = patternCompleted[difficulty] ?? 0;
            final patternsTotal = patternTotals[difficulty] ?? 0;
            final indicatorsDone = indicatorCompleted[difficulty] ?? 0;
            final indicatorsTotal = indicatorTotals[difficulty] ?? 0;

            final isPatternUnlocked = gamification.isDifficultyUnlocked(
              module: LearningConstants.modulePattern,
              difficulty: difficulty,
            );
            final isIndicatorUnlocked = gamification.isDifficultyUnlocked(
              module: LearningConstants.moduleIndicator,
              difficulty: difficulty,
            );
            final fullyLocked = !isPatternUnlocked && !isIndicatorUnlocked;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.95)
                      : AppColors.surface.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => setState(() => _selectedDifficulty = difficulty),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fullyLocked ? Icons.lock : Icons.lock_open,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${difficulty.label} ${patternsDone + indicatorsDone}/${patternsTotal + indicatorsTotal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPatternTab({
    required BuildContext context,
    required List<LessonModel> lessons,
    required GamificationNotifier gamification,
    required Map<String, CandlestickPattern> patternById,
    required Map<String, CandlestickPattern> patternByTitle,
  }) {
    final filtered = lessons
        .where((lesson) =>
            LearningConstants.fromDifficultyLabel(lesson.difficulty) ==
            _selectedDifficulty)
        .toList();

    final unlocked = gamification.isDifficultyUnlocked(
      module: LearningConstants.modulePattern,
      difficulty: _selectedDifficulty,
    );

    if (!unlocked) {
      return _buildLockedState(_selectedDifficulty);
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No pattern lessons in this difficulty.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      itemBuilder: (context, index) {
        final lesson = filtered[index];
        final pattern =
            patternById[lesson.id] ?? patternByTitle[_normalize(lesson.title)];
        final isCompleted = _isPatternLessonCompleted(
          lesson: lesson,
          gamification: gamification,
          patternByTitle: patternByTitle,
        );

        return _buildLessonCardShell(
          accentColor: isCompleted ? AppColors.bullish : AppColors.primary,
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _openLesson(
            context: context,
            lesson: lesson,
            patternById: patternById,
            patternByTitle: patternByTitle,
            indicatorsById: const {},
            gamification: gamification,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PatternPreviewTile(pattern: pattern, isCompleted: isCompleted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(
                          label: _selectedDifficulty.label,
                          icon: Icons.school,
                        ),
                        _buildMetaChip(
                          label: isCompleted ? 'Completed' : 'Start lesson',
                          icon: isCompleted
                              ? Icons.check_circle
                              : Icons.play_arrow,
                          foreground: isCompleted
                              ? AppColors.bullish
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicatorTab({
    required BuildContext context,
    required List<LessonModel> lessons,
    required GamificationNotifier gamification,
    required Map<String, IndicatorModel> indicatorsById,
  }) {
    final filtered = lessons
        .where((lesson) =>
            LearningConstants.fromDifficultyLabel(lesson.difficulty) ==
            _selectedDifficulty)
        .toList();

    final unlocked = gamification.isDifficultyUnlocked(
      module: LearningConstants.moduleIndicator,
      difficulty: _selectedDifficulty,
    );

    if (!unlocked) {
      return _buildLockedState(_selectedDifficulty);
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No indicator lessons in this difficulty.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      itemBuilder: (context, index) {
        final lesson = filtered[index];
        final indicator = indicatorsById[lesson.id];
        final isCompleted = gamification.isIndicatorCompleted(lesson.id);

        return _buildLessonCardShell(
          accentColor: isCompleted ? AppColors.bullish : AppColors.accent,
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            if (indicator == null) return;
            _openIndicatorDetail(context, indicator, isCompleted);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndicatorVisualPreview(
                indicator: indicator,
                width: 94,
                height: 74,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(
                          label: _selectedDifficulty.label,
                          icon: Icons.timeline,
                        ),
                        _buildMetaChip(
                          label: isCompleted ? 'Completed' : 'View diagram',
                          icon: isCompleted
                              ? Icons.check_circle
                              : Icons.show_chart,
                          foreground: isCompleted
                              ? AppColors.bullish
                              : AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedState(ContentDifficulty difficulty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider.withOpacity(0.9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 52, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                '${difficulty.label} Lessons Locked',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                LearningConstants.unlockRuleText(difficulty),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCardShell({
    required Widget child,
    required VoidCallback onTap,
    required Color accentColor,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withOpacity(0.32)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required String label,
    required IconData icon,
    Color foreground = AppColors.textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson({
    required BuildContext context,
    required LessonModel lesson,
    required Map<String, CandlestickPattern> patternById,
    required Map<String, CandlestickPattern> patternByTitle,
    required Map<String, IndicatorModel> indicatorsById,
    required GamificationNotifier gamification,
  }) async {
    if (lesson.type == LearningConstants.moduleIndicator) {
      final indicator = indicatorsById[lesson.id];
      if (indicator != null) {
        await _openIndicatorDetail(
          context,
          indicator,
          gamification.isIndicatorCompleted(indicator.id),
        );
      }
      return;
    }

    final pattern =
        patternById[lesson.id] ?? patternByTitle[_normalize(lesson.title)];

    if (pattern != null) {
      await AdService.instance.showInterstitialAd();
      if (context.mounted) {
        context.push('/pattern/${pattern.id}', extra: pattern);
      }
      return;
    }

    await _openVirtualPatternLesson(context, lesson, gamification);
  }

  Future<void> _openVirtualPatternLesson(
    BuildContext context,
    LessonModel lesson,
    GamificationNotifier gamification,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(lesson.description),
              const SizedBox(height: 12),
              ...lesson.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(point)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await gamification.completeLesson(lesson.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mark as Completed (+10 XP)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openIndicatorDetail(
    BuildContext context,
    IndicatorModel indicator,
    bool isCompleted,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IndicatorDetailSheet(
        indicator: indicator,
        isCompleted: isCompleted,
      ),
    );
  }

  Map<ContentDifficulty, int> _difficultyTotals(List<LessonModel> lessons) {
    final totals = <ContentDifficulty, int>{
      for (final difficulty in LearningConstants.difficultyOrder) difficulty: 0,
    };

    for (final lesson in lessons) {
      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      totals[difficulty] = (totals[difficulty] ?? 0) + 1;
    }

    return totals;
  }

  Map<ContentDifficulty, int> _patternCompletionByDifficulty({
    required List<LessonModel> lessons,
    required GamificationNotifier gamification,
    required Map<String, CandlestickPattern> patternByTitle,
  }) {
    final completion = <ContentDifficulty, int>{
      for (final difficulty in LearningConstants.difficultyOrder) difficulty: 0,
    };

    for (final lesson in lessons) {
      final isDone = _isPatternLessonCompleted(
        lesson: lesson,
        gamification: gamification,
        patternByTitle: patternByTitle,
      );
      if (!isDone) continue;

      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      completion[difficulty] = (completion[difficulty] ?? 0) + 1;
    }

    return completion;
  }

  Map<ContentDifficulty, int> _indicatorCompletionByDifficulty({
    required List<LessonModel> lessons,
    required GamificationNotifier gamification,
  }) {
    final completion = <ContentDifficulty, int>{
      for (final difficulty in LearningConstants.difficultyOrder) difficulty: 0,
    };

    for (final lesson in lessons) {
      if (!gamification.completedIndicators.contains(lesson.id)) continue;
      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      completion[difficulty] = (completion[difficulty] ?? 0) + 1;
    }

    return completion;
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

  LessonModel? _resolveDailyLesson({
    required String dailyLessonId,
    required List<LessonModel> patternLessons,
    required List<LessonModel> indicatorLessons,
  }) {
    if (dailyLessonId.isEmpty) return null;

    final all = [...patternLessons, ...indicatorLessons];

    for (final lesson in all) {
      if (lesson.id == dailyLessonId) {
        return lesson;
      }
    }

    return null;
  }

  bool _isPatternLessonCompleted({
    required LessonModel lesson,
    required GamificationNotifier gamification,
    required Map<String, CandlestickPattern> patternByTitle,
  }) {
    if (gamification.completedLessons.contains(lesson.id)) {
      return true;
    }

    final pattern = patternByTitle[_normalize(lesson.title)];
    if (pattern == null) return false;
    return gamification.completedLessons.contains(pattern.id);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _PatternPreviewTile extends StatelessWidget {
  final CandlestickPattern? pattern;
  final bool isCompleted;

  const _PatternPreviewTile({
    required this.pattern,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = pattern?.imagePath ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 94,
        height: 74,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF152238), Color(0xFF1C2E45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.candlestick_chart,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.candlestick_chart,
                      color: AppColors.primary,
                      size: 30,
                    ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.bullish.withOpacity(0.9)
                      : Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.play_arrow,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorVisualPreview extends StatelessWidget {
  final IndicatorModel? indicator;
  final double width;
  final double height;
  final double borderRadius;
  final bool showLabel;

  const _IndicatorVisualPreview({
    required this.indicator,
    required this.width,
    required this.height,
    this.borderRadius = 14,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = indicator?.image.trim() ?? '';
    final label = indicator?.title ?? 'Indicator';
    final stableSeed = _stableSeed(indicator?.id ?? label);

    Widget placeholder = _IndicatorChartPlaceholder(
      label: label,
      seed: stableSeed,
    );

    if (imagePath.isNotEmpty) {
      placeholder = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _IndicatorChartPlaceholder(label: label, seed: stableSeed),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            if (showLabel)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Visual Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _stableSeed(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }
}

class _IndicatorChartPlaceholder extends StatelessWidget {
  final String label;
  final int seed;

  const _IndicatorChartPlaceholder({
    required this.label,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    final gradientStart = Color.lerp(
          const Color(0xFF101927),
          AppColors.surfaceRaised,
          0.22 + (random.nextDouble() * 0.34),
        ) ??
        const Color(0xFF101927);
    final gradientEnd = Color.lerp(
          const Color(0xFF1A2C44),
          AppColors.primary.withOpacity(0.85),
          0.14 + (random.nextDouble() * 0.38),
        ) ??
        const Color(0xFF1A2C44);
    final initials = label
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(3)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _IndicatorPlaceholderPainter(seed: seed),
            ),
          ),
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorPlaceholderPainter extends CustomPainter {
  final int seed;

  _IndicatorPlaceholderPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final phase = random.nextDouble() * math.pi * 2;
    final barDensity = 14 + random.nextInt(6);
    final trendFreq = 1.7 + random.nextDouble() * 1.8;
    final signalFreq = 2.4 + random.nextDouble() * 2.2;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barsPaint = Paint()
      ..color = Color.lerp(
        AppColors.accent,
        AppColors.primarySoft,
        random.nextDouble(),
      )!
          .withOpacity(0.38);
    final barWidth = size.width / (barDensity + 8);
    for (int i = 0; i < barDensity; i++) {
      final x = 8 + (barWidth + 3) * i;
      final wave = (math.sin((i / barDensity) * math.pi * 2 + phase) + 1) / 2;
      final noise = random.nextDouble() * 0.08;
      final barHeight = size.height * (0.18 + (wave * 0.38) + noise);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight - 4, barWidth, barHeight),
          const Radius.circular(2),
        ),
        barsPaint,
      );
    }

    final trendPaint = Paint()
      ..color = Color.lerp(
        AppColors.primarySoft,
        AppColors.accent,
        random.nextDouble() * 0.35,
      )!
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final trendPath = Path();
    final trendAmplitude = size.height * (0.1 + random.nextDouble() * 0.08);
    final trendSlope = size.height * (0.06 + random.nextDouble() * 0.12);
    for (int i = 0; i < 30; i++) {
      final t = i / 29;
      final x = t * size.width;
      final y = (size.height * 0.58) -
          (math.sin((t * math.pi * trendFreq) + phase) * trendAmplitude) +
          (t * -trendSlope);
      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }
    }
    canvas.drawPath(trendPath, trendPaint);

    final signalPaint = Paint()
      ..color = Color.lerp(
        AppColors.bullish,
        AppColors.primarySoft,
        random.nextDouble(),
      )!
          .withOpacity(0.82)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final signalPath = Path();
    final signalAmplitude = size.height * (0.05 + random.nextDouble() * 0.07);
    for (int i = 0; i < 30; i++) {
      final t = i / 29;
      final x = t * size.width;
      final y = (size.height * 0.42) +
          (math.cos((t * math.pi * signalFreq) + (phase / 2)) *
              signalAmplitude);
      if (i == 0) {
        signalPath.moveTo(x, y);
      } else {
        signalPath.lineTo(x, y);
      }
    }
    canvas.drawPath(signalPath, signalPaint);
  }

  @override
  bool shouldRepaint(covariant _IndicatorPlaceholderPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

class _IndicatorDetailSheet extends StatefulWidget {
  final IndicatorModel indicator;
  final bool isCompleted;

  const _IndicatorDetailSheet({
    required this.indicator,
    required this.isCompleted,
  });

  @override
  State<_IndicatorDetailSheet> createState() => _IndicatorDetailSheetState();
}

class _IndicatorDetailSheetState extends State<_IndicatorDetailSheet> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final indicator = widget.indicator;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withOpacity(0.7)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                indicator.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    label: indicator.difficulty,
                    icon: Icons.school,
                    color: AppColors.primary,
                  ),
                  _buildInfoChip(
                    label: _isCompleted ? 'Completed' : 'Not completed',
                    icon: _isCompleted ? Icons.check_circle : Icons.pending,
                    color: _isCompleted ? AppColors.bullish : AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _IndicatorVisualPreview(
                indicator: indicator,
                width: double.infinity,
                height: 190,
                borderRadius: 16,
                showLabel: true,
              ),
              const SizedBox(height: 14),
              const Text(
                'Definition',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                indicator.definition,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Key Points',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ...indicator.keyPoints.map(
                (point) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.divider.withOpacity(0.55)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        indicator.useCase,
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCompleted ? null : _completeIndicator,
                  icon: Icon(
                    _isCompleted ? Icons.verified : Icons.check_circle_outline,
                  ),
                  label: Text(
                    _isCompleted
                        ? 'Already Completed'
                        : 'Mark as Completed (+10 XP)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeIndicator() async {
    await context
        .read<GamificationNotifier>()
        .completeIndicator(widget.indicator.id);
    if (!mounted) return;

    setState(() => _isCompleted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Indicator lesson completed! +10 XP'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
