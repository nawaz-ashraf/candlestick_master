enum ContentDifficulty {
  basic,
  intermediate,
  hard,
  advanced,
}

extension ContentDifficultyX on ContentDifficulty {
  String get key {
    switch (this) {
      case ContentDifficulty.basic:
        return 'basic';
      case ContentDifficulty.intermediate:
        return 'intermediate';
      case ContentDifficulty.hard:
        return 'hard';
      case ContentDifficulty.advanced:
        return 'advanced';
    }
  }

  String get label {
    switch (this) {
      case ContentDifficulty.basic:
        return 'Basic';
      case ContentDifficulty.intermediate:
        return 'Intermediate';
      case ContentDifficulty.hard:
        return 'Hard';
      case ContentDifficulty.advanced:
        return 'Advanced';
    }
  }
}

class LearningConstants {
  const LearningConstants._();

  static const List<ContentDifficulty> difficultyOrder = [
    ContentDifficulty.basic,
    ContentDifficulty.intermediate,
    ContentDifficulty.hard,
    ContentDifficulty.advanced,
  ];

  static const String modulePattern = 'pattern';
  static const String moduleChallenge = 'challenge';
  static const String moduleIndicator = 'indicator';

  static String unlockKey({
    required String module,
    required ContentDifficulty difficulty,
  }) {
    return '$module:${difficulty.key}';
  }

  static String unlockRuleText(ContentDifficulty difficulty) {
    final previous = previousDifficulty(difficulty);
    if (previous == null) {
      return 'Available by default';
    }
    return 'Complete all ${previous.label} lessons first';
  }

  static ContentDifficulty? previousDifficulty(ContentDifficulty difficulty) {
    final index = difficultyOrder.indexOf(difficulty);
    if (index <= 0) return null;
    return difficultyOrder[index - 1];
  }

  static ContentDifficulty? nextDifficulty(ContentDifficulty difficulty) {
    final index = difficultyOrder.indexOf(difficulty);
    if (index < 0 || index >= difficultyOrder.length - 1) return null;
    return difficultyOrder[index + 1];
  }

  static List<String> baseUnlockedDifficultyKeys() {
    return [
      unlockKey(
        module: modulePattern,
        difficulty: ContentDifficulty.basic,
      ),
      unlockKey(
        module: moduleChallenge,
        difficulty: ContentDifficulty.basic,
      ),
      unlockKey(
        module: moduleIndicator,
        difficulty: ContentDifficulty.basic,
      ),
    ];
  }

  static ContentDifficulty fromDifficultyLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'basic') return ContentDifficulty.basic;
    if (normalized == 'intermediate') return ContentDifficulty.intermediate;
    if (normalized == 'hard') return ContentDifficulty.hard;
    if (normalized == 'advanced') return ContentDifficulty.advanced;
    if (normalized == 'beginner') return ContentDifficulty.basic;
    return ContentDifficulty.basic;
  }
}
