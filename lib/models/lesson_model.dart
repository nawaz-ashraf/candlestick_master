class LessonModel {
  final String id;
  final String title;
  final String type; // candlestick | indicator
  final String difficulty;
  final String description;
  final String image;
  final List<String> keyPoints;
  final String unlockedBy;

  const LessonModel({
    required this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.description,
    required this.image,
    required this.keyPoints,
    required this.unlockedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'difficulty': difficulty,
      'description': description,
      'image': image,
      'keyPoints': keyPoints,
      'unlockedBy': unlockedBy,
    };
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String,
      image: json['image'] as String? ?? '',
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          const <String>[],
      unlockedBy: json['unlockedBy'] as String? ?? '',
    );
  }
}
