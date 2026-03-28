class CandlestickPattern {
  final String id;
  final String name;
  final String category;
  final String bias; // Bullish, Bearish, Neutral
  final String description;
  final List<String> keyRules;
  final String trend;
  final String imagePath;
  final String difficulty;

  CandlestickPattern({
    required this.id,
    required this.name,
    required this.category,
    required this.bias,
    required this.description,
    required this.keyRules,
    required this.trend,
    required this.imagePath,
    required this.difficulty,
  });

  factory CandlestickPattern.fromJson(Map<String, dynamic> json) {
    return CandlestickPattern(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      bias: json['bias'] as String? ?? 'Neutral',
      description: json['description'] as String,
      keyRules: (json['key_rules'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      trend: json['trend'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'bias': bias,
      'description': description,
      'key_rules': keyRules,
      'trend': trend,
      'image_path': imagePath,
      'difficulty': difficulty,
    };
  }
}
