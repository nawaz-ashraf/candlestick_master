// =============================================================================
// User Progress Notifier - State Management for Learned Patterns & Quiz Stats
// =============================================================================
// Manages:
// - Learned patterns persistence via SharedPreferences
// - Quiz statistics (total questions, correct answers, accuracy)
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProgressNotifier extends ChangeNotifier {
  // SharedPreferences keys
  static const String _learnedPatternsKey = 'learned_patterns';
  static const String _totalQuestionsKey = 'quiz_total_questions';
  static const String _correctAnswersKey = 'quiz_correct_answers';

  // State
  Set<String> _learnedPatternIds = {};
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  bool _isInitialized = false;

  // Getters
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

  /// Initialize by loading data from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load learned patterns
      final learnedList = prefs.getStringList(_learnedPatternsKey) ?? [];
      _learnedPatternIds = learnedList.toSet();

      // Load quiz stats
      _totalQuestions = prefs.getInt(_totalQuestionsKey) ?? 0;
      _correctAnswers = prefs.getInt(_correctAnswersKey) ?? 0;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing UserProgressNotifier: $e');
    }
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

  /// Reset all quiz statistics
  Future<void> resetQuizStats() async {
    _totalQuestions = 0;
    _correctAnswers = 0;
    notifyListeners();
    await _saveQuizStats();
  }

  /// Reset all learned patterns
  Future<void> resetLearnedPatterns() async {
    _learnedPatternIds.clear();
    notifyListeners();
    await _saveLearnedPatterns();
  }

  // Private helper methods
  Future<void> _saveLearnedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _learnedPatternsKey, _learnedPatternIds.toList());
    } catch (e) {
      debugPrint('Error saving learned patterns: $e');
    }
  }

  Future<void> _saveQuizStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_totalQuestionsKey, _totalQuestions);
      await prefs.setInt(_correctAnswersKey, _correctAnswers);
    } catch (e) {
      debugPrint('Error saving quiz stats: $e');
    }
  }
}
