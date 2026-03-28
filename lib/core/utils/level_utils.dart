import 'package:candlestick_master/core/constants/reward_constants.dart';

class LevelInfo {
  final int level;
  final int currentXp;
  final int xpIntoCurrentLevel;
  final int xpForNextLevel;
  final int xpToNextLevel;
  final int totalXpForCurrentLevelStart;
  final int totalXpForNextLevel;
  final double progress;

  const LevelInfo({
    required this.level,
    required this.currentXp,
    required this.xpIntoCurrentLevel,
    required this.xpForNextLevel,
    required this.xpToNextLevel,
    required this.totalXpForCurrentLevelStart,
    required this.totalXpForNextLevel,
    required this.progress,
  });
}

class LevelUtils {
  const LevelUtils._();

  static int xpRequiredForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    return safeLevel * RewardConstants.xpPerLevel;
  }

  static int totalXpToReachLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    if (safeLevel <= 1) return 0;

    final n = safeLevel - 1;
    return (n * (n + 1) ~/ 2) * RewardConstants.xpPerLevel;
  }

  static LevelInfo fromXp(int xp) {
    final safeXp = xp < 0 ? 0 : xp;

    var level = 1;
    var remainingXp = safeXp;

    while (remainingXp >= xpRequiredForLevel(level)) {
      remainingXp -= xpRequiredForLevel(level);
      level += 1;
    }

    final xpForNext = xpRequiredForLevel(level);
    final xpToNext = xpForNext - remainingXp;
    final currentLevelStart = safeXp - remainingXp;
    final nextLevelTotal = currentLevelStart + xpForNext;
    final progress = xpForNext == 0 ? 0.0 : remainingXp / xpForNext;

    return LevelInfo(
      level: level,
      currentXp: safeXp,
      xpIntoCurrentLevel: remainingXp,
      xpForNextLevel: xpForNext,
      xpToNextLevel: xpToNext,
      totalXpForCurrentLevelStart: currentLevelStart,
      totalXpForNextLevel: nextLevelTotal,
      progress: progress.clamp(0.0, 1.0),
    );
  }
}
