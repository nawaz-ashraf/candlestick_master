class UserProgress {
  final String patternId;
  final int attempts;
  final int correct;
  final int streak;
  final DateTime lastPracticed;

  UserProgress({
    required this.patternId,
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    required this.lastPracticed,
  });
  
  // Mastery Calculation
  String get masteryLevel {
    if (attempts == 0) return "Novice";
    double accuracy = correct / attempts;
    if (attempts > 20 && accuracy > 0.9) return "Master";
    if (attempts > 10 && accuracy > 0.7) return "Proficient";
    if (attempts > 5 && accuracy > 0.5) return "Learner";
    return "Novice";
  }

  Map<String, dynamic> toMap() {
    return {
      'pattern_id': patternId,
      'attempts': attempts,
      'correct': correct,
      'streak': streak,
      'last_practiced': lastPracticed.toIso8601String(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      patternId: map['pattern_id'],
      attempts: map['attempts'] ?? 0,
      correct: map['correct'] ?? 0,
      streak: map['streak'] ?? 0,
      lastPracticed: DateTime.parse(map['last_practiced']),
    );
  }
}
