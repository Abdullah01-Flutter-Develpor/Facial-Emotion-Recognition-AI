import 'package:image/image.dart' as img;

import 'package:demo_app/features/emotion_result/models/emotion_analysis.dart';

/// Stable boundary between face preparation and the future TFLite model.
/// No prediction is invented when a model is not bundled with the app.
class EmotionInferenceService {
  Future<EmotionAnalysis> classify(img.Image croppedFace) async {
    throw const EmotionModelUnavailableException();
  }
}

class EmotionModelUnavailableException implements Exception {
  const EmotionModelUnavailableException();

  @override
  String toString() => 'An emotion model has not been added to this build.';
}
