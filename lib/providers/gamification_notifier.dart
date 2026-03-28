// =============================================================================
// GamificationNotifier - State Management for Gamification System
// =============================================================================
// Manages all gamification logic: XP, levels, coins, streaks, daily lessons,
// challenge progression, lesson completion, quiz answers, and revision tracking.
// Auto-persists all state changes via StorageService.
// =============================================================================

import 'dart:math';

import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/constants/reward_constants.dart';
import 'package:candlestick_master/core/services/storage_service.dart';
import 'package:candlestick_master/core/utils/date_utils.dart';
import 'package:candlestick_master/models/habit_user_progress.dart';
import 'package:flutter/foundation.dart';

class GamificationNotifier extends ChangeNotifier {
  final StorageService _storage = StorageService();

  UserProgress _data = const UserProgress();
  bool _isInitialized = false;

  // ============================================
  // Getters
  // ============================================
  UserProgress get data => _data;
  bool get isInitialized => _isInitialized;

  int get xp => _data.xp;
  int get coins => _data.coins;
  int get streak => _data.streak;
  int get bestStreak => _data.bestStreak;
  int get level => _data.level;
  int get xpInCurrentLevel => _data.xpInCurrentLevel;
  int get xpForNextLevel => _data.xpForNextLevel;
  int get xpToNextLevel => _data.xpToNextLevel;
  double get levelProgress => _data.levelProgress;
  String get userId => _data.userId;
  String get dailyLessonId => _data.dailyLessonId;
  String get dailyLessonDate => _data.dailyLessonDate;
  List<String> get completedLessons => _data.completedLessons;
  List<String> get completedIndicators => _data.completedIndicators;
  List<String> get completedChallenges => _data.completedChallenges;
  List<String> get unlockedDifficulties => _data.resolvedUnlockedDifficulties;
  List<String> get wrongAnswers => _data.wrongAnswers;
  int get sessionCount => _data.sessionCount;

  /// Check if daily challenge is available (not completed today)
  bool get isDailyChallengeAvailable {
    if (!_data.dailyChallengeCompleted) return true;
    final today = _todayString();
    return _data.dailyChallengeDate != today;
  }

  /// Check if daily challenge was completed today
  bool get isDailyChallengeCompletedToday {
    final today = _todayString();
    return _data.dailyChallengeCompleted && _data.dailyChallengeDate == today;
  }

  // ============================================
  // Initialization
  // ============================================

  /// Load persisted gamification data
  Future<void> initialize() async {
    if (_isInitialized) return;

    _data = await _storage.loadGamificationData();
    _isInitialized = true;

    // Check if streak needs to be reset (missed a day)
    var requiresPersist = false;

    _checkStreakOnStartup();
    requiresPersist = _resetDailyChallengeFlagOnStartup() || requiresPersist;
    requiresPersist = _ensureUserId() || requiresPersist;
    requiresPersist = _ensureBaseUnlocks() || requiresPersist;

    notifyListeners();

    if (requiresPersist) {
      await _persist();
    }
  }

  // ============================================
  // XP System
  // ============================================

  /// Add XP and auto-persist
  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    _data = _data.copyWith(xp: _data.xp + amount);
    notifyListeners();
    await _persist();
  }

  // ============================================
  // Coin System
  // ============================================

  /// Add coins and auto-persist
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _data = _data.copyWith(coins: _data.coins + amount);
    notifyListeners();
    await _persist();
  }

  /// Spend coins (returns false if insufficient)
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_data.coins < amount) return false;
    _data = _data.copyWith(coins: _data.coins - amount);
    notifyListeners();
    await _persist();
    return true;
  }

  // ============================================
  // Streak System
  // ============================================

  /// Update streak when user completes an activity today
  void _updateStreak() {
    final today = _todayString();

    // Already active today — no change needed
    if (_data.lastActiveDate == today) {
      return;
    }

    final yesterday = _yesterdayString();
    int newStreak;

    if (_data.lastActiveDate == yesterday) {
      // Consecutive day — increment streak
      newStreak = _data.streak + 1;
    } else if (_data.lastActiveDate.isEmpty) {
      // First ever activity
      newStreak = 1;
    } else {
      // Missed a day — reset streak
      newStreak = 1;
    }

    final newBestStreak =
        newStreak > _data.bestStreak ? newStreak : _data.bestStreak;

    _data = _data.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      lastActiveDate: today,
    );
  }

  /// Check streak status on app startup — reset if missed a day
  void _checkStreakOnStartup() {
    if (_data.lastActiveDate.isEmpty) return;

    final today = _todayString();
    final yesterday = _yesterdayString();

    // If last active was today or yesterday, streak is fine
    if (_data.lastActiveDate == today || _data.lastActiveDate == yesterday) {
      return;
    }

    // Missed more than one day — reset streak
    _data = _data.copyWith(streak: 0);
  }

  // ============================================
  // Lesson Completion (+10 XP)
  // ============================================

  /// Mark a lesson as completed and award XP
  Future<void> completeLesson(String lessonId) async {
    if (lessonId.trim().isEmpty) return;

    final lessons = List<String>.from(_data.completedLessons);
    final isNewCompletion = !lessons.contains(lessonId);

    if (isNewCompletion) {
      lessons.add(lessonId);
    }

    _data = _data.copyWith(
      xp: _data.xp + (isNewCompletion ? RewardConstants.lessonXp : 0),
      completedLessons: lessons,
    );

    _updateStreak();
    notifyListeners();
    await _persist();
  }

  /// Check if a lesson is completed
  bool isLessonCompleted(String lessonId) {
    return _data.completedLessons.contains(lessonId);
  }

  /// Mark an indicator lesson as completed and award XP once.
  Future<void> completeIndicator(String indicatorId) async {
    if (indicatorId.trim().isEmpty) return;

    final indicators = List<String>.from(_data.completedIndicators);
    final isNewCompletion = !indicators.contains(indicatorId);

    if (isNewCompletion) {
      indicators.add(indicatorId);
    }

    _data = _data.copyWith(
      xp: _data.xp + (isNewCompletion ? RewardConstants.lessonXp : 0),
      completedIndicators: indicators,
    );

    _updateStreak();
    notifyListeners();
    await _persist();
  }

  bool isIndicatorCompleted(String indicatorId) {
    return _data.completedIndicators.contains(indicatorId);
  }

  // ============================================
  // Quiz Answer Recording (+20 XP correct, track wrong)
  // ============================================

  /// Record a quiz answer result
  Future<void> recordQuizAnswer(String patternId, bool isCorrect) async {
    final isRevisable = _isRevisablePatternId(patternId);

    if (isCorrect) {
      _data = _data.copyWith(xp: _data.xp + RewardConstants.quizCorrectXp);

      // Remove from wrong answers if it was there (they got it right now)
      final wrongs = List<String>.from(_data.wrongAnswers);
      if (isRevisable) {
        wrongs.remove(patternId);
      }
      _data = _data.copyWith(wrongAnswers: wrongs);
    } else {
      // Add to wrong answers for revision
      final wrongs = List<String>.from(_data.wrongAnswers);
      if (isRevisable && !wrongs.contains(patternId)) {
        wrongs.add(patternId);
      }
      _data = _data.copyWith(wrongAnswers: wrongs);
    }

    _updateStreak();
    notifyListeners();
    await _persist();
  }

  /// Record a daily challenge answer without awarding per-question XP.
  Future<void> recordChallengeAnswer(String patternId, bool isCorrect) async {
    final wrongs = List<String>.from(_data.wrongAnswers);
    final isRevisable = _isRevisablePatternId(patternId);

    if (isCorrect) {
      if (isRevisable) {
        wrongs.remove(patternId);
      }
    } else {
      if (isRevisable && !wrongs.contains(patternId)) {
        wrongs.add(patternId);
      }
    }

    _data = _data.copyWith(wrongAnswers: wrongs);
    _updateStreak();
    notifyListeners();
    await _persist();
  }

  // ============================================
  // Daily Challenge (+30 XP, +50 Coins)
  // ============================================

  /// Complete the daily challenge
  Future<void> completeDailyChallenge() async {
    final today = _todayString();

    if (_data.dailyChallengeCompleted && _data.dailyChallengeDate == today) {
      return;
    }

    final completedChallenges = List<String>.from(_data.completedChallenges);
    final dailyChallengeId = 'daily_$today';
    if (!completedChallenges.contains(dailyChallengeId)) {
      completedChallenges.add(dailyChallengeId);
    }

    _data = _data.copyWith(
      xp: _data.xp + RewardConstants.dailyChallengeXp,
      coins: _data.coins + RewardConstants.dailyChallengeCoins,
      dailyChallengeDate: today,
      dailyChallengeCompleted: true,
      completedChallenges: completedChallenges,
    );

    _updateStreak();
    notifyListeners();
    await _persist();
  }

  /// Mark a challenge from the library as complete and grant reward once.
  Future<void> completeChallenge({
    required String challengeId,
    required int xpReward,
  }) async {
    if (challengeId.trim().isEmpty) return;

    final completedChallenges = List<String>.from(_data.completedChallenges);
    final isNewCompletion = !completedChallenges.contains(challengeId);

    if (isNewCompletion) {
      completedChallenges.add(challengeId);
    }

    _data = _data.copyWith(
      completedChallenges: completedChallenges,
      xp: _data.xp + (isNewCompletion ? xpReward : 0),
    );

    _updateStreak();
    notifyListeners();
    await _persist();
  }

  bool isChallengeCompleted(String challengeId) {
    return _data.completedChallenges.contains(challengeId);
  }

  // ============================================
  // Rewarded Ad (+100 Coins)
  // ============================================

  /// Award coins for watching a rewarded ad
  Future<void> rewardAdCoins() async {
    _data =
        _data.copyWith(coins: _data.coins + RewardConstants.rewardedAdCoins);
    notifyListeners();
    await _persist();
  }

  // ============================================
  // Session Tracking (for Ad frequency)
  // ============================================

  /// Increment session count
  Future<void> incrementSession() async {
    _data = _data.copyWith(sessionCount: _data.sessionCount + 1);
    await _persist();
  }

  /// Check if interstitial should show (every 3 sessions)
  bool get shouldShowInterstitial {
    if (_data.sessionCount == 0) return false;
    return _data.sessionCount % RewardConstants.sessionsPerInterstitial == 0;
  }

  // ============================================
  // Revision — Remove wrong answer after correct retry
  // ============================================

  /// Remove a pattern from wrong answers (user got it right in revision)
  Future<void> removeFromWrongAnswers(String patternId) async {
    final wrongs = List<String>.from(_data.wrongAnswers);
    wrongs.remove(patternId);
    _data = _data.copyWith(wrongAnswers: wrongs);
    notifyListeners();
    await _persist();
  }

  // ============================================
  // Daily Lesson Selection
  // ============================================

  /// Select and persist a deterministic daily lesson from unlocked lesson IDs.
  Future<String> ensureDailyLesson(List<String> unlockedLessonIds) async {
    final today = _todayString();
    final candidates = unlockedLessonIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (candidates.isEmpty) {
      if (_data.dailyLessonId.isNotEmpty || _data.dailyLessonDate != today) {
        _data = _data.copyWith(
          dailyLessonId: '',
          dailyLessonDate: today,
        );
        notifyListeners();
        await _persist();
      }
      return '';
    }

    if (_data.dailyLessonDate == today &&
        candidates.contains(_data.dailyLessonId)) {
      return _data.dailyLessonId;
    }

    final selection = _selectLessonForDate(candidates, today);
    _data = _data.copyWith(
      dailyLessonId: selection,
      dailyLessonDate: today,
    );
    notifyListeners();
    await _persist();
    return selection;
  }

  // ============================================
  // Difficulty Unlocking
  // ============================================

  bool isDifficultyUnlocked({
    required String module,
    required ContentDifficulty difficulty,
  }) {
    final key = LearningConstants.unlockKey(
      module: module,
      difficulty: difficulty,
    );
    return _data.resolvedUnlockedDifficulties.contains(key);
  }

  Future<void> unlockDifficulty({
    required String module,
    required ContentDifficulty difficulty,
  }) async {
    final key = LearningConstants.unlockKey(
      module: module,
      difficulty: difficulty,
    );

    final keys = {..._data.resolvedUnlockedDifficulties};
    final hasChanged = keys.add(key);
    if (!hasChanged) return;

    _data = _data.copyWith(unlockedDifficulties: keys.toList(growable: false));
    notifyListeners();
    await _persist();
  }

  Future<void> syncUnlockedDifficulties({
    required String module,
    required Map<ContentDifficulty, int> completedByDifficulty,
    required Map<ContentDifficulty, int> totalByDifficulty,
  }) async {
    final keys = {..._data.resolvedUnlockedDifficulties};
    var hasChanged = false;

    for (final difficulty in LearningConstants.difficultyOrder) {
      final key = LearningConstants.unlockKey(
        module: module,
        difficulty: difficulty,
      );

      if (difficulty == ContentDifficulty.basic) {
        if (keys.add(key)) {
          hasChanged = true;
        }
        continue;
      }

      final previous = LearningConstants.previousDifficulty(difficulty);
      if (previous == null) continue;

      final previousTotal = totalByDifficulty[previous] ?? 0;
      final previousCompleted = completedByDifficulty[previous] ?? 0;

      if (previousTotal > 0 && previousCompleted >= previousTotal) {
        if (keys.add(key)) {
          hasChanged = true;
        }
      }
    }

    if (!hasChanged) return;

    _data = _data.copyWith(unlockedDifficulties: keys.toList(growable: false));
    notifyListeners();
    await _persist();
  }

  // ============================================
  // Helpers
  // ============================================

  /// Get today's date as ISO string (yyyy-MM-dd)
  String _todayString() {
    return AppDateUtils.todayKey();
  }

  /// Get yesterday's date as ISO string
  String _yesterdayString() {
    return AppDateUtils.yesterdayKey();
  }

  bool _isRevisablePatternId(String patternId) {
    return patternId.isNotEmpty && !patternId.startsWith('static_');
  }

  /// Reset daily challenge flag if it belongs to an older day.
  bool _resetDailyChallengeFlagOnStartup() {
    final today = _todayString();
    if (_data.dailyChallengeCompleted && _data.dailyChallengeDate != today) {
      _data = _data.copyWith(dailyChallengeCompleted: false);
      return true;
    }
    return false;
  }

  bool _ensureUserId() {
    if (_data.userId.isNotEmpty) return false;

    _data = _data.copyWith(
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
    );
    return true;
  }

  bool _ensureBaseUnlocks() {
    final current = _data.resolvedUnlockedDifficulties;
    if (listEquals(current, _data.unlockedDifficulties) && current.isNotEmpty) {
      return false;
    }

    _data = _data.copyWith(unlockedDifficulties: current);
    return true;
  }

  String _selectLessonForDate(List<String> candidates, String dateKey) {
    final seed = _stableHash('$dateKey|${_data.userId}');
    final random = Random(seed);
    return candidates[random.nextInt(candidates.length)];
  }

  int _stableHash(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  /// Persist current data to storage
  Future<void> _persist() async {
    await _storage.saveGamificationData(_data);
  }
}
