// =============================================================================
// Static Quiz Question Model
// =============================================================================
// Model for questions loaded from the quiz_questions.json question bank.
// These are pre-defined questions covering:
// - Pattern-based questions
// - Trading knowledge questions
// - Lesson-based learning questions
// =============================================================================

class StaticQuizQuestion {
  final String id;
  final String category; // 'pattern', 'trading', 'lesson'
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  StaticQuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory StaticQuizQuestion.fromJson(Map<String, dynamic> json) {
    return StaticQuizQuestion(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}
