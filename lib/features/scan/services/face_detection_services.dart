import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: true,
    ),
  );

  Future<List<Face>> detect(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _detector.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}