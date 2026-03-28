class ChallengeModel {
  final String id;
  final String difficulty;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final int xpReward;
  final bool completed;

  const ChallengeModel({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.xpReward,
    this.completed = false,
  });

  ChallengeModel copyWith({bool? completed}) {
    return ChallengeModel(
      id: id,
      difficulty: difficulty,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      xpReward: xpReward,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'xpReward': xpReward,
      'completed': completed,
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      difficulty: json['difficulty'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String,
      xpReward: json['xpReward'] as int,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
