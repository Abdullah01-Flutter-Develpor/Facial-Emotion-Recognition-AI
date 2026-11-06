class EmotionAnalysis {
  const EmotionAnalysis({
    required this.emotion,
    required this.confidence,
    required this.createdAt,
    this.scores = const {},
    this.id,
    this.captureSource = 'unknown',
  });

  final String? id;
  final String emotion;
  final double confidence;
  final DateTime createdAt;
  final Map<String, double> scores;

  /// Where the source photo was selected. Legacy records remain `unknown`.
  final String captureSource;

  String get emoji => switch (emotion.toLowerCase()) {
    'angry' => '😠',
    'disgust' => '🤢',
    'fear' => '😨',
    'happy' => '😊',
    'sad' => '😔',
    'surprise' => '😮',
    'neutral' => '😐',
    _ => '✨',
  };

  bool get isPositive =>
      const {'happy', 'surprise', 'neutral'}.contains(emotion.toLowerCase());

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'emotion': emotion,
    'confidence': confidence,
    'scores': scores,
    'createdAt': createdAt.toIso8601String(),
    'captureSource': captureSource,
  };

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json, {String? id}) =>
      EmotionAnalysis(
        id: id ?? json['id'] as String?,
        emotion: json['emotion'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        scores: (json['scores'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
        captureSource: json['captureSource'] as String? ?? 'unknown',
      );
}
