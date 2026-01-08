import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:candlestick_master/data/models/pattern_model.dart';
import 'package:candlestick_master/data/models/quiz_question.dart';
import 'package:candlestick_master/data/models/static_quiz_question.dart';

// =============================================================================
// Quiz Generator - Creates Mixed Quizzes
// =============================================================================
// Generates quizzes by mixing:
// 1. Static questions from quiz_questions.json (50+ pre-defined questions)
// 2. Dynamic questions generated from candlestick patterns
// =============================================================================

class QuizGenerator {
  final Random _random = Random();
  List<StaticQuizQuestion>? _staticQuestions;
  bool _isLoading = false;

  /// Load static questions from assets
  Future<void> loadStaticQuestions() async {
    if (_staticQuestions != null || _isLoading) return;

    _isLoading = true;
    try {
      final jsonString =
          await rootBundle.loadString('assets/quiz_questions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _staticQuestions = jsonList
          .map((json) =>
              StaticQuizQuestion.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Loaded ${_staticQuestions!.length} static quiz questions');
    } catch (e) {
      debugPrint('Error loading static questions: $e');
      _staticQuestions = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Generate a mixed quiz with static and dynamic questions
  Future<List<QuizQuestion>> generateMixedQuiz(
    List<CandlestickPattern> patterns, {
    int count = 10,
  }) async {
    // Ensure static questions are loaded
    await loadStaticQuestions();

    final List<QuizQuestion> questions = [];

    // Determine mix: roughly 60% static, 40% dynamic (if static available)
    final staticCount =
        (_staticQuestions != null && _staticQuestions!.isNotEmpty)
            ? (count * 0.6).round()
            : 0;
    final dynamicCount = count - staticCount;

    // Add static questions
    if (staticCount > 0 && _staticQuestions != null) {
      final shuffledStatic = List<StaticQuizQuestion>.from(_staticQuestions!)
        ..shuffle(_random);
      final selectedStatic = shuffledStatic.take(staticCount);

      for (final sq in selectedStatic) {
        // Create a placeholder pattern for static questions
        final placeholderPattern = CandlestickPattern(
          id: 'static_${sq.id}',
          name: 'General Knowledge',
          category: sq.category,
          bias: 'Neutral',
          description: sq.explanation,
          keyRules: [],
          trend: '',
          imagePath: '',
          difficulty: 'Intermediate',
        );

        questions.add(QuizQuestion(
          id: sq.id,
          questionText: sq.question,
          imageUrl: null,
          options: sq.options,
          correctOptionIndex: sq.correctIndex,
          explanation: sq.explanation,
          correctPattern: placeholderPattern,
        ));
      }
    }

    // Add dynamic pattern-based questions
    if (dynamicCount > 0 && patterns.isNotEmpty) {
      final dynamicQuestions = generateQuiz(patterns, count: dynamicCount);
      questions.addAll(dynamicQuestions);
    }

    // Shuffle the final mix
    questions.shuffle(_random);

    return questions;
  }

  /// Generate dynamic questions from patterns (original method)
  List<QuizQuestion> generateQuiz(List<CandlestickPattern> patterns,
      {int count = 5}) {
    if (patterns.isEmpty) return [];

    // Filter out intro chapters if necessary (IDs 1-6 are usually intro)
    // Assuming we want to quiz on actual patterns.
    final quizPatterns =
        patterns.where((p) => p.category != 'General').toList();
    if (quizPatterns.isEmpty) return [];

    List<QuizQuestion> questions = [];

    for (int i = 0; i < count; i++) {
      final target = quizPatterns[_random.nextInt(quizPatterns.length)];
      final type =
          QuestionType.values[_random.nextInt(QuestionType.values.length)];

      questions.add(_createQuestion(target, quizPatterns, type));
    }

    return questions;
  }

  QuizQuestion _createQuestion(CandlestickPattern target,
      List<CandlestickPattern> allPatterns, QuestionType type) {
    String questionText = "";
    String? imageUrl;
    List<String> options = [];
    int correctIndex = 0;
    String explanation = target.description;

    // Get 3 distractors
    final distractors = _getDistractors(target, allPatterns, 3);
    final allOptions = [...distractors, target]..shuffle(_random);
    correctIndex = allOptions.indexOf(target);

    switch (type) {
      case QuestionType.identifyName:
        questionText = "Which candlestick pattern is shown in the image?";
        imageUrl = target.imagePath;
        options = allOptions.map((p) => p.name).toList();
        break;

      case QuestionType.identifyBias:
        questionText =
            "What is the market bias for the '${target.name}' pattern?";
        // Options are fixed for Bias
        options = ["Bullish", "Bearish", "Neutral", "Indecisive"];
        // Find correct index
        int biasIndex = options.indexOf(target.bias);
        if (biasIndex == -1) biasIndex = 2; // Default to neutral if not found
        correctIndex = biasIndex;
        imageUrl = null;
        break;

      case QuestionType.identifyDescription:
        questionText =
            "Which pattern matches this description?\n'${_truncate(target.description, 100)}...'";
        options = allOptions.map((p) => p.name).toList();
        imageUrl = null;
        break;
    }

    return QuizQuestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      questionText: questionText,
      imageUrl: imageUrl,
      options: options,
      correctOptionIndex: correctIndex,
      explanation: explanation,
      correctPattern: target,
    );
  }

  List<CandlestickPattern> _getDistractors(
      CandlestickPattern target, List<CandlestickPattern> all, int count) {
    final others = all.where((p) => p.id != target.id).toList();
    others.shuffle(_random);
    return others.take(count).toList();
  }

  String _truncate(String text, int length) {
    if (text.length <= length) return text;
    return "${text.substring(0, length)}...";
  }
}
