import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo_app/core/state/analysis_store.dart';
import 'package:demo_app/features/emotion_result/models/emotion_analysis.dart';

// A signed-out store only uses local storage, so these tests run without
// Firebase.
EmotionAnalysis scan(String emotion, int day) => EmotionAnalysis(
  emotion: emotion,
  confidence: 0.8,
  createdAt: DateTime(2026, 11, day),
  scores: {emotion: 0.8},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps the newest result first', () async {
    final store = AnalysisStore();
    await store.add(scan('sad', 1));
    await store.add(scan('happy', 3));
    await store.add(scan('angry', 2));

    expect(store.totalScans, 3);
    expect(store.latest?.emotion, 'happy');
    expect(store.items.map((item) => item.emotion), ['happy', 'angry', 'sad']);
  });

  test('saves results to the device', () async {
    final store = AnalysisStore();
    await store.add(scan('happy', 1));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('emotion_analyses_v2_local'), contains('happy'));
    expect(store.items.single.id, startsWith('local_'));
  });

  test('deletes a single result', () async {
    final store = AnalysisStore();
    await store.add(scan('sad', 1));
    await store.add(scan('happy', 2));

    await store.delete(store.items.last);

    expect(store.totalScans, 1);
    expect(store.latest?.emotion, 'happy');
  });

  test('works out the most common emotion and positive share', () async {
    final store = AnalysisStore();
    expect(store.mostCommonEmotion, isNull);
    expect(store.positiveMoodPercent, 0);

    await store.add(scan('happy', 1));
    await store.add(scan('happy', 2));
    await store.add(scan('angry', 3));
    await store.add(scan('neutral', 4));

    expect(store.mostCommonEmotion, 'happy');
    expect(store.positiveMoodPercent, 75);
  });
}
