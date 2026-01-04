import 'dart:math';
import 'package:candlestick_master/data/models/pattern_model.dart';
import 'package:candlestick_master/data/models/quiz_question.dart';



class QuizGenerator {
  final Random _random = Random();

  List<QuizQuestion> generateQuiz(List<CandlestickPattern> patterns, {int count = 5}) {
    if (patterns.isEmpty) return [];
    
    // Filter out intro chapters if necessary (IDs 1-6 are usually intro)
    // Assuming we want to quiz on actual patterns.
    final quizPatterns = patterns.where((p) => p.category != 'General').toList();
    if (quizPatterns.isEmpty) return [];

    List<QuizQuestion> questions = [];

    for (int i = 0; i < count; i++) {
      final target = quizPatterns[_random.nextInt(quizPatterns.length)];
      final type = QuestionType.values[_random.nextInt(QuestionType.values.length)];
      
      questions.add(_createQuestion(target, quizPatterns, type));
    }
    
    return questions;
  }

  QuizQuestion _createQuestion(CandlestickPattern target, List<CandlestickPattern> allPatterns, QuestionType type) {
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
        questionText = "What is the market bias for the '${target.name}' pattern?";
        // Options are fixed for Bias
        options = ["Bullish", "Bearish", "Neutral", "Indecisive"];
        // Find correct index
        int biasIndex = options.indexOf(target.bias);
        if (biasIndex == -1) biasIndex = 2; // Default to neutral if not found
        correctIndex = biasIndex;
        imageUrl = null; 
        break;
        
      case QuestionType.identifyDescription:
        questionText = "Which pattern matches this description?\n'${_truncate(target.description, 100)}...'";
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

  List<CandlestickPattern> _getDistractors(CandlestickPattern target, List<CandlestickPattern> all, int count) {
    final others = all.where((p) => p.id != target.id).toList();
    others.shuffle(_random);
    return others.take(count).toList();
  }
  
  String _truncate(String text, int length) {
    if (text.length <= length) return text;
    return "${text.substring(0, length)}...";
  }
}
