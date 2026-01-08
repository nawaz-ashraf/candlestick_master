import 'package:flutter/foundation.dart';
import '../../domain/logic/quiz_generator.dart';
import '../../data/models/quiz_question.dart';
import '../../data/models/quiz_settings.dart';
import '../../data/models/user_progress.dart';
import '../../data/models/pattern_model.dart';
import '../../data/repositories/database_service.dart';

class QuizNotifier extends ChangeNotifier {
  final QuizGenerator _generator = QuizGenerator();
  final DatabaseService _db = DatabaseService();

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOption;
  bool _isLoading = false;
  QuizSettings? _currentSettings;
  List<CandlestickPattern> _patterns = [];

  // Getters
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get answered => _answered;
  int? get selectedOption => _selectedOption;
  bool get isLoading => _isLoading;
  QuizSettings? get currentSettings => _currentSettings;
  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentIndex] : null;
  bool get isFinished =>
      _questions.isNotEmpty &&
      _currentIndex >= _questions.length - 1 &&
      _answered;

  /// Calculate accuracy percentage
  double get accuracy {
    if (_questions.isEmpty) return 0.0;
    return (_score / _questions.length) * 100;
  }

  Future<void> startQuiz(
    List<CandlestickPattern> patterns, {
    QuizSettings? settings,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Store patterns and settings for restart
    _patterns = patterns;
    _currentSettings = settings ?? QuizSettings.medium;

    // Generate mixed quiz with static + dynamic questions
    _questions = await _generator.generateMixedQuiz(
      patterns,
      count: _currentSettings!.questionCount,
    );
    _currentIndex = 0;
    _score = 0;
    _answered = false;
    _selectedOption = null;

    _isLoading = false;
    notifyListeners();
  }

  /// Restart quiz with the same settings
  Future<void> restartQuiz() async {
    if (_currentSettings != null && _patterns.isNotEmpty) {
      await startQuiz(_patterns, settings: _currentSettings);
    }
  }

  Future<void> submitAnswer(int optionIndex) async {
    if (_answered) return;

    _answered = true;
    _selectedOption = optionIndex;

    final question = currentQuestion;
    if (question == null) return;

    final isCorrect = optionIndex == question.correctOptionIndex;
    if (isCorrect) _score++;

    notifyListeners();

    // Save Progress Asynchronously
    await _saveProgress(question, isCorrect);
  }

  Future<void> nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _answered = false;
      _selectedOption = null;
      notifyListeners();
    }
  }

  Future<void> _saveProgress(QuizQuestion question, bool isCorrect) async {
    final patternId = question.correctPattern.id;
    final currentProgress = await _db.getProgress(patternId);

    final newAttempts = (currentProgress?.attempts ?? 0) + 1;
    final newCorrect = (currentProgress?.correct ?? 0) + (isCorrect ? 1 : 0);
    final newStreak = isCorrect ? (currentProgress?.streak ?? 0) + 1 : 0;

    await _db.saveProgress(UserProgress(
      patternId: patternId,
      attempts: newAttempts,
      correct: newCorrect,
      streak: newStreak,
      lastPracticed: DateTime.now(),
    ));
  }
}
