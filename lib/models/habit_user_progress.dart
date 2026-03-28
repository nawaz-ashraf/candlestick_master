import 'dart:collection';

import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/utils/level_utils.dart';

// Habit and gamification state persisted in SharedPreferences.
class UserProgress {
  final String userId;
  final int xp;
  final int coins;
  final int streak;
  final int bestStreak;
  final String lastActiveDate;
  final List<String> completedLessons;
  final List<String> completedIndicators;
  final List<String> completedChallenges;
  final List<String> unlockedDifficulties;
  final List<String> wrongAnswers;
  final String dailyLessonId;
  final String dailyLessonDate;

  // Internal fields used for daily challenge and ad session behavior.
  final String dailyChallengeDate;
  final bool dailyChallengeCompleted;
  final int sessionCount;

  const UserProgress({
    this.userId = '',
    this.xp = 0,
    this.coins = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastActiveDate = '',
    this.completedLessons = const [],
    this.completedIndicators = const [],
    this.completedChallenges = const [],
    this.unlockedDifficulties = const [],
    this.wrongAnswers = const [],
    this.dailyLessonId = '',
    this.dailyLessonDate = '',
    this.dailyChallengeDate = '',
    this.dailyChallengeCompleted = false,
    this.sessionCount = 0,
  });

  List<String> get resolvedUnlockedDifficulties {
    final merged = LinkedHashSet<String>.from(
      [
        ...LearningConstants.baseUnlockedDifficultyKeys(),
        ...unlockedDifficulties,
      ],
    );
    return merged.toList(growable: false);
  }

  LevelInfo get levelInfo => LevelUtils.fromXp(xp);

  int get level => levelInfo.level;

  int get xpInCurrentLevel => levelInfo.xpIntoCurrentLevel;

  int get xpForNextLevel => levelInfo.xpForNextLevel;

  int get xpToNextLevel => levelInfo.xpToNextLevel;

  double get levelProgress {
    if (xpForNextLevel == 0) return 0;
    return xpInCurrentLevel / xpForNextLevel;
  }

  UserProgress copyWith({
    String? userId,
    int? xp,
    int? coins,
    int? streak,
    int? bestStreak,
    String? lastActiveDate,
    List<String>? completedLessons,
    List<String>? completedIndicators,
    List<String>? completedChallenges,
    List<String>? unlockedDifficulties,
    List<String>? wrongAnswers,
    String? dailyLessonId,
    String? dailyLessonDate,
    String? dailyChallengeDate,
    bool? dailyChallengeCompleted,
    int? sessionCount,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      completedLessons: completedLessons ?? this.completedLessons,
      completedIndicators: completedIndicators ?? this.completedIndicators,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      unlockedDifficulties: unlockedDifficulties ?? this.unlockedDifficulties,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      dailyLessonId: dailyLessonId ?? this.dailyLessonId,
      dailyLessonDate: dailyLessonDate ?? this.dailyLessonDate,
      dailyChallengeDate: dailyChallengeDate ?? this.dailyChallengeDate,
      dailyChallengeCompleted:
          dailyChallengeCompleted ?? this.dailyChallengeCompleted,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'xp': xp,
      'coins': coins,
      'streak': streak,
      'bestStreak': bestStreak,
      'lastActiveDate': lastActiveDate,
      'completedLessons': completedLessons,
      'completedIndicators': completedIndicators,
      'completedChallenges': completedChallenges,
      'unlockedDifficulties': resolvedUnlockedDifficulties,
      'wrongAnswers': wrongAnswers,
      'dailyLessonId': dailyLessonId,
      'dailyLessonDate': dailyLessonDate,
      'dailyChallengeDate': dailyChallengeDate,
      'dailyChallengeCompleted': dailyChallengeCompleted,
      'sessionCount': sessionCount,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final unlockedFromJson = _toStringList(json['unlockedDifficulties']);
    final mergedUnlocks = LinkedHashSet<String>.from(
      [
        ...LearningConstants.baseUnlockedDifficultyKeys(),
        ...unlockedFromJson,
      ],
    ).toList(growable: false);

    return UserProgress(
      userId: json['userId'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      completedLessons: _toStringList(json['completedLessons']),
      completedIndicators: _toStringList(json['completedIndicators']),
      completedChallenges: _toStringList(json['completedChallenges']),
      unlockedDifficulties: mergedUnlocks,
      wrongAnswers: _toStringList(json['wrongAnswers']),
      dailyLessonId: json['dailyLessonId'] as String? ?? '',
      dailyLessonDate: json['dailyLessonDate'] as String? ?? '',
      dailyChallengeDate: json['dailyChallengeDate'] as String? ?? '',
      dailyChallengeCompleted:
          json['dailyChallengeCompleted'] as bool? ?? false,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List<dynamic>) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
