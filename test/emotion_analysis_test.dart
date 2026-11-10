import 'package:flutter_test/flutter_test.dart';

import 'package:demo_app/features/emotion_result/models/emotion_analysis.dart';

void main() {
  final analysis = EmotionAnalysis(
    id: 'abc',
    emotion: 'happy',
    confidence: 0.92,
    createdAt: DateTime.utc(2026, 11, 9, 10, 30),
    scores: const {'happy': 0.92, 'neutral': 0.08},
    captureSource: 'camera_selfie',
  );

  test('toJson and fromJson keep every field', () {
    final copy = EmotionAnalysis.fromJson(analysis.toJson());

    expect(copy.id, 'abc');
    expect(copy.emotion, 'happy');
    expect(copy.confidence, 0.92);
    expect(copy.createdAt, analysis.createdAt);
    expect(copy.scores, analysis.scores);
    expect(copy.captureSource, 'camera_selfie');
  });

  test('older records without scores or source still load', () {
    final old = EmotionAnalysis.fromJson({
      'emotion': 'sad',
      'confidence': 0.5,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(old.scores, isEmpty);
    expect(old.captureSource, 'unknown');
    expect(old.id, isNull);
  });

  test('an id passed to fromJson wins over the one in the map', () {
    final copy = EmotionAnalysis.fromJson(analysis.toJson(), id: 'firestore-id');
    expect(copy.id, 'firestore-id');
  });

  test('every FER-2013 class has its own emoji', () {
    const classes = [
      'angry',
      'disgust',
      'fear',
      'happy',
      'neutral',
      'sad',
      'surprise',
    ];
    final emojis = {
      for (final label in classes)
        EmotionAnalysis(
          emotion: label,
          confidence: 1,
          createdAt: DateTime(2026),
        ).emoji,
    };
    expect(emojis.length, classes.length);
    expect(emojis.contains('✨'), isFalse);
  });

  test('happy, surprise and neutral count as positive', () {
    EmotionAnalysis withEmotion(String emotion) => EmotionAnalysis(
      emotion: emotion,
      confidence: 0.5,
      createdAt: DateTime(2026),
    );

    expect(withEmotion('Happy').isPositive, isTrue);
    expect(withEmotion('surprise').isPositive, isTrue);
    expect(withEmotion('neutral').isPositive, isTrue);
    expect(withEmotion('angry').isPositive, isFalse);
    expect(withEmotion('sad').isPositive, isFalse);
  });
}
