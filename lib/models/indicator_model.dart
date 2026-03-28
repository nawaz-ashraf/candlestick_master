class IndicatorModel {
  final String id;
  final String title;
  final String definition;
  final List<String> keyPoints;
  final String image;
  final String useCase;
  final String difficulty;

  const IndicatorModel({
    required this.id,
    required this.title,
    required this.definition,
    required this.keyPoints,
    required this.image,
    required this.useCase,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'definition': definition,
      'keyPoints': keyPoints,
      'image': image,
      'useCase': useCase,
      'difficulty': difficulty,
    };
  }

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      id: json['id'] as String,
      title: json['title'] as String,
      definition: json['definition'] as String,
      keyPoints: (json['keyPoints'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      image: json['image'] as String? ?? '',
      useCase: json['useCase'] as String,
      difficulty: json['difficulty'] as String? ?? 'Basic',
    );
  }
}
