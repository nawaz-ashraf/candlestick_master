// =============================================================================
// GamificationData - User Gamification State Model
// =============================================================================
// Stores all gamification-related data: XP, coins, streaks, daily challenge
// status, completed lessons, and wrong answers for revision.
// Persisted via SharedPreferences as JSON.
// =============================================================================

class GamificationData {
  final int xp;
  final int coins;
  final int streak;
  final int bestStreak;
  final String lastActiveDate; // ISO 8601 date string (yyyy-MM-dd)
  final List<String> completedLessons; // Pattern IDs
  final List<String> wrongAnswers; // Question identifiers (patternId)
  final String dailyChallengeDate; // ISO 8601 date string
  final bool dailyChallengeCompleted;
  final int sessionCount;

  const GamificationData({
    this.xp = 0,
    this.coins = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastActiveDate = '',
    this.completedLessons = const [],
    this.wrongAnswers = const [],
    this.dailyChallengeDate = '',
    this.dailyChallengeCompleted = false,
    this.sessionCount = 0,
  });

  /// Current level based on XP (every 100 XP = 1 level)
  int get level => xp ~/ 100;

  /// XP progress within the current level (0-99)
  int get xpInCurrentLevel => xp % 100;

  /// XP required to reach the next level
  int get xpForNextLevel => 100;

  /// Progress fraction within current level (0.0 - 1.0)
  double get levelProgress => xpInCurrentLevel / xpForNextLevel;

  /// Create a copy with updated fields
  GamificationData copyWith({
    int? xp,
    int? coins,
    int? streak,
    int? bestStreak,
    String? lastActiveDate,
    List<String>? completedLessons,
    List<String>? wrongAnswers,
    String? dailyChallengeDate,
    bool? dailyChallengeCompleted,
    int? sessionCount,
  }) {
    return GamificationData(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      completedLessons: completedLessons ?? this.completedLessons,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      dailyChallengeDate: dailyChallengeDate ?? this.dailyChallengeDate,
      dailyChallengeCompleted:
          dailyChallengeCompleted ?? this.dailyChallengeCompleted,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'coins': coins,
      'streak': streak,
      'bestStreak': bestStreak,
      'lastActiveDate': lastActiveDate,
      'completedLessons': completedLessons,
      'wrongAnswers': wrongAnswers,
      'dailyChallengeDate': dailyChallengeDate,
      'dailyChallengeCompleted': dailyChallengeCompleted,
      'sessionCount': sessionCount,
    };
  }

  /// Deserialize from JSON map with null-safe defaults
  factory GamificationData.fromJson(Map<String, dynamic> json) {
    return GamificationData(
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      completedLessons: (json['completedLessons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      wrongAnswers: (json['wrongAnswers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dailyChallengeDate: json['dailyChallengeDate'] as String? ?? '',
      dailyChallengeCompleted:
          json['dailyChallengeCompleted'] as bool? ?? false,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }
}
