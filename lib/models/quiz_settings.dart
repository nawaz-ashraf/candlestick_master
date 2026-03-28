// =============================================================================
// Quiz Settings Model
// =============================================================================
// Configuration for quiz sessions including difficulty and question count.
// Used by quiz selection screen and quiz notifier for dynamic quiz generation.
// =============================================================================

enum QuizDifficulty {
  easy,
  medium,
  hard,
}

class QuizSettings {
  final QuizDifficulty difficulty;
  final int questionCount;

  const QuizSettings({
    required this.difficulty,
    required this.questionCount,
  });

  /// Predefined settings for each difficulty level
  static const QuizSettings easy = QuizSettings(
    difficulty: QuizDifficulty.easy,
    questionCount: 5,
  );

  static const QuizSettings medium = QuizSettings(
    difficulty: QuizDifficulty.medium,
    questionCount: 10,
  );

  static const QuizSettings hard = QuizSettings(
    difficulty: QuizDifficulty.hard,
    questionCount: 15,
  );

  /// Get display label for the difficulty
  String get difficultyLabel {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
    }
  }

  /// Get description for the difficulty level
  String get description {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Perfect for beginners. Quick practice session.';
      case QuizDifficulty.medium:
        return 'Balanced challenge for regular practice.';
      case QuizDifficulty.hard:
        return 'Comprehensive test for advanced learners.';
    }
  }

  /// Get icon data for the difficulty
  String get iconName {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'bolt';
      case QuizDifficulty.medium:
        return 'trending_up';
      case QuizDifficulty.hard:
        return 'psychology';
    }
  }
}
