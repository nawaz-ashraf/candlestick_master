// =============================================================================
// User Progress Notifier - State Management for Learned Patterns & Quiz Stats
// =============================================================================
// Manages:
// - Learned patterns persistence via SharedPreferences (isolated per account)
// - Quiz statistics (total questions, correct answers, accuracy) isolated per account
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProgressNotifier extends ChangeNotifier {
  // Legacy un-scoped keys
  static const String _legacyLearnedKey = 'learned_patterns';
  static const String _legacyTotalKey = 'quiz_total_questions';
  static const String _legacyCorrectKey = 'quiz_correct_answers';

  /// Scoped SharedPreferences keys per authenticated UID or guest
  static String learnedPatternsKey([String? userId]) {
    final uid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
    return 'user_${uid}_learned_patterns';
  }

  static String totalQuestionsKey([String? userId]) {
    final uid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
    return 'user_${uid}_quiz_total_questions';
  }

  static String correctAnswersKey([String? userId]) {
    final uid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
    return 'user_${uid}_quiz_correct_answers';
  }

  // State
  String _currentUserId = 'guest';
  Set<String> _learnedPatternIds = {};
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  bool _isInitialized = false;

  // Getters
  String get currentUserId => _currentUserId;
  Set<String> get learnedPatternIds => _learnedPatternIds;
  int get learnedCount => _learnedPatternIds.length;
  int get totalQuestions => _totalQuestions;
  int get correctAnswers => _correctAnswers;
  bool get isInitialized => _isInitialized;

  /// Calculate quiz accuracy as a percentage (0-100)
  double get quizAccuracy {
    if (_totalQuestions == 0) return 0.0;
    return (_correctAnswers / _totalQuestions) * 100;
  }

  /// Check if a pattern is marked as learned
  bool isPatternLearned(String patternId) {
    return _learnedPatternIds.contains(patternId);
  }

  /// Initialize by loading data from SharedPreferences for the active user
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      String? authUid;
      try {
        authUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}

      final activeUid = (userId != null && userId.trim().isNotEmpty)
          ? userId.trim()
          : (authUid ?? 'guest');
      _currentUserId = activeUid;
      await _loadForCurrentUser();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing UserProgressNotifier: $e');
    }
  }

  /// Switch the active user identity and reload user-scoped progress
  Future<void> switchUser(String? userId) async {
    final newUid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
    _currentUserId = newUid;
    await _loadForCurrentUser();
    notifyListeners();
    debugPrint('UserProgressNotifier: Switched to user $_currentUserId (learned: ${_learnedPatternIds.length})');
  }

  /// Clear in-memory progress on logout
  void clearOnSignOut() {
    _currentUserId = 'guest';
    _learnedPatternIds.clear();
    _totalQuestions = 0;
    _correctAnswers = 0;
    notifyListeners();
    debugPrint('UserProgressNotifier: Cleared in-memory progress on sign out');
  }

  Future<void> _loadForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lKey = learnedPatternsKey(_currentUserId);
    final tKey = totalQuestionsKey(_currentUserId);
    final cKey = correctAnswersKey(_currentUserId);

    // Safe migration for legacy unauthenticated guest
    if (_currentUserId == 'guest') {
      if (!prefs.containsKey(lKey) && prefs.containsKey(_legacyLearnedKey)) {
        final legacyList = prefs.getStringList(_legacyLearnedKey) ?? [];
        await prefs.setStringList(lKey, legacyList);
        await prefs.remove(_legacyLearnedKey);
      }
      if (!prefs.containsKey(tKey) && prefs.containsKey(_legacyTotalKey)) {
        final total = prefs.getInt(_legacyTotalKey) ?? 0;
        await prefs.setInt(tKey, total);
        await prefs.remove(_legacyTotalKey);
      }
      if (!prefs.containsKey(cKey) && prefs.containsKey(_legacyCorrectKey)) {
        final correct = prefs.getInt(_legacyCorrectKey) ?? 0;
        await prefs.setInt(cKey, correct);
        await prefs.remove(_legacyCorrectKey);
      }
    }

    final learnedList = prefs.getStringList(lKey) ?? [];
    _learnedPatternIds = learnedList.toSet();
    _totalQuestions = prefs.getInt(tKey) ?? 0;
    _correctAnswers = prefs.getInt(cKey) ?? 0;
  }

  /// Toggle learned status for a pattern
  Future<void> toggleLearned(String patternId) async {
    if (_learnedPatternIds.contains(patternId)) {
      _learnedPatternIds.remove(patternId);
    } else {
      _learnedPatternIds.add(patternId);
    }
    notifyListeners();
    await _saveLearnedPatterns();
  }

  /// Mark a pattern as learned
  Future<void> markAsLearned(String patternId) async {
    if (!_learnedPatternIds.contains(patternId)) {
      _learnedPatternIds.add(patternId);
      notifyListeners();
      await _saveLearnedPatterns();
    }
  }

  /// Mark a pattern as not learned
  Future<void> markAsNotLearned(String patternId) async {
    if (_learnedPatternIds.contains(patternId)) {
      _learnedPatternIds.remove(patternId);
      notifyListeners();
      await _saveLearnedPatterns();
    }
  }

  /// Record a quiz question result
  Future<void> recordQuizResult({required bool isCorrect}) async {
    _totalQuestions++;
    if (isCorrect) {
      _correctAnswers++;
    }
    notifyListeners();
    await _saveQuizStats();
  }

  /// Record multiple quiz results at once (for batch updates)
  Future<void> recordQuizBatch({
    required int totalAnswered,
    required int correctCount,
  }) async {
    _totalQuestions += totalAnswered;
    _correctAnswers += correctCount;
    notifyListeners();
    await _saveQuizStats();
  }

  /// Reset all quiz statistics for current user
  Future<void> resetQuizStats() async {
    _totalQuestions = 0;
    _correctAnswers = 0;
    notifyListeners();
    await _saveQuizStats();
  }

  /// Reset all learned patterns for current user
  Future<void> resetLearnedPatterns() async {
    _learnedPatternIds.clear();
    notifyListeners();
    await _saveLearnedPatterns();
  }

  // Private helper methods
  Future<void> _saveLearnedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = learnedPatternsKey(_currentUserId);
      await prefs.setStringList(key, _learnedPatternIds.toList());
    } catch (e) {
      debugPrint('Error saving learned patterns: $e');
    }
  }

  Future<void> _saveQuizStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(totalQuestionsKey(_currentUserId), _totalQuestions);
      await prefs.setInt(correctAnswersKey(_currentUserId), _correctAnswers);
    } catch (e) {
      debugPrint('Error saving quiz stats: $e');
    }
  }
}
