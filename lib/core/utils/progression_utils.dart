import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/models/challenge_model.dart';
import 'package:candlestick_master/models/lesson_model.dart';

class ProgressionUtils {
  const ProgressionUtils._();

  static Map<ContentDifficulty, List<LessonModel>> groupLessonsByDifficulty(
    List<LessonModel> lessons,
  ) {
    final grouped = <ContentDifficulty, List<LessonModel>>{
      for (final difficulty in LearningConstants.difficultyOrder)
        difficulty: <LessonModel>[],
    };

    for (final lesson in lessons) {
      final difficulty =
          LearningConstants.fromDifficultyLabel(lesson.difficulty);
      grouped[difficulty]!.add(lesson);
    }

    return grouped;
  }

  static Map<ContentDifficulty, List<ChallengeModel>>
      groupChallengesByDifficulty(
    List<ChallengeModel> challenges,
  ) {
    final grouped = <ContentDifficulty, List<ChallengeModel>>{
      for (final difficulty in LearningConstants.difficultyOrder)
        difficulty: <ChallengeModel>[],
    };

    for (final challenge in challenges) {
      final difficulty =
          LearningConstants.fromDifficultyLabel(challenge.difficulty);
      grouped[difficulty]!.add(challenge);
    }

    return grouped;
  }

  static bool isDifficultyUnlocked({
    required ContentDifficulty difficulty,
    required List<String> completedIds,
    required Map<ContentDifficulty, int> totals,
    required Map<ContentDifficulty, int> completions,
  }) {
    if (difficulty == ContentDifficulty.basic) return true;

    final previousDifficulty = LearningConstants.previousDifficulty(difficulty);
    if (previousDifficulty == null) return true;

    final previousTotal = totals[previousDifficulty] ?? 0;
    if (previousTotal == 0) return false;

    final previousCompleted = completions[previousDifficulty] ?? 0;
    return previousCompleted >= previousTotal;
  }

  static double completionRatio({
    required int completed,
    required int total,
  }) {
    if (total <= 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0);
  }

  static bool isDifficultyCompleted({
    required ContentDifficulty difficulty,
    required Map<ContentDifficulty, int> totals,
    required Map<ContentDifficulty, int> completions,
  }) {
    final total = totals[difficulty] ?? 0;
    if (total <= 0) return false;
    final completed = completions[difficulty] ?? 0;
    return completed >= total;
  }
}
