import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

class EmotionPrediction {
  const EmotionPrediction(this.label, this.confidence, this.scores);
  final String label;
  final double confidence;
  final Map<String, double> scores;
}



class EmotionClassifier {
  static const _classes = [
    'angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise',
  ];
  static const _sourceSize = 48;
  static const _inputSize = 112;
  static const _mean = [0.485, 0.456, 0.406];
  static const _std = [0.229, 0.224, 0.225];

  OrtSession? _session;

  Future<void> _ensureLoaded() async {
    _session ??= await OnnxRuntime().createSessionFromAsset(
      'assets/models/emotion_model.onnx',
    );
  }

  Float32List _preprocess(img.Image face, {required bool flip}) {
    
    
    final gray = img.grayscale(face);
    final source = img.copyResize(
      gray,
      width: _sourceSize,
      height: _sourceSize,
      interpolation: img.Interpolation.average,
    );
    final resized = img.copyResize(
      source,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.average,
    );

    
    
    
    const plane = _inputSize * _inputSize;
    final data = Float32List(3 * plane);
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final sourceX = flip ? _inputSize - 1 - x : x;
        final value = resized.getPixel(sourceX, y).r / 255.0;
        final i = y * _inputSize + x;
        for (var channel = 0; channel < 3; channel++) {
          final offset = channel * plane;
          data[offset + i] = (value - _mean[channel]) / _std[channel];
        }
      }
    }
    return data;
  }

  List<double> _softmax(List<double> logits) {
    final maxValue = logits.reduce(math.max);
    final exps = logits.map((value) => math.exp(value - maxValue)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((value) => value / sum).toList();
  }

  Future<EmotionPrediction> predict(img.Image face) async {
    if (face.width == 0 || face.height == 0) {
      throw ArgumentError('Face crop is empty.');
    }
    await _ensureLoaded();
    Future<List<double>> runSingle({required bool flip}) async {
      final input = await OrtValue.fromList(
        _preprocess(face, flip: flip),
        [1, 3, _inputSize, _inputSize],
      );
      Map<String, OrtValue>? outputs;
      try {
        outputs = await _session!.run({'input': input});
        if (outputs.isEmpty) throw StateError('The model returned no outputs.');
        final raw = (await outputs.values.first.asFlattenedList())
            .map((value) => (value as num).toDouble())
            .toList();
        if (raw.length != _classes.length) {
          throw StateError('Unexpected model output size: ${raw.length}.');
        }
        return _softmax(raw);
      } finally {
        await input.dispose();
        if (outputs != null) {
          for (final output in outputs.values) {
            await output.dispose();
          }
        }
      }
    }

    final original = await runSingle(flip: false);
    final flipped = await runSingle(flip: true);
      final probabilities = List<double>.generate(
        _classes.length,
        (index) => (original[index] + flipped[index]) / 2,
      );
      var best = 0;
      for (var i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[best]) best = i;
      }
    return EmotionPrediction(
      _classes[best],
      probabilities[best],
      {for (var i = 0; i < _classes.length; i++) _classes[i]: probabilities[i]},
    );
  }

  Future<void> close() async {
    await _session?.close();
    _session = null;
  }
}
