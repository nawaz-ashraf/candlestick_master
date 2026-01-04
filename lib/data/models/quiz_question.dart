import '../models/pattern_model.dart';

enum QuestionType {
  identifyName, // Show image, choose name
  identifyBias, // Show name, choose Bullish/Bearish
  identifyDescription, // Show name, choose description/key rule
}

class QuizQuestion {
  final String id;
  final String questionText;
  final String? imageUrl;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final CandlestickPattern correctPattern;

  QuizQuestion({
    required this.id,
    required this.questionText,
    this.imageUrl,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.correctPattern,
  });
}
