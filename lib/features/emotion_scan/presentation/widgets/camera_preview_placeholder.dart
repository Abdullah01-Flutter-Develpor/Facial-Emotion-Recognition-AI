import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CameraPreviewPlaceholder extends StatefulWidget {
  const CameraPreviewPlaceholder({
    super.key,
    required this.onFaceReady,
    this.onCaptureSource,
  });

  final ValueChanged<img.Image?> onFaceReady;
  final ValueChanged<String>? onCaptureSource;

  @override
  State<CameraPreviewPlaceholder> createState() => _CameraState();
}

class _CameraState extends State<CameraPreviewPlaceholder> {
  final _picker = ImagePicker();
  final _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  XFile? _image;
  img.Image? _croppedFace;
  bool _isAnalyzing = false;
  String? _error;

  Future<void> _showSourceOptions() async {
    if (_isAnalyzing) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xff1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Choose a face photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xff60A5FA),
              ),
              title: const Text(
                'Take a live photo',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Open your camera now',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xff60A5FA),
              ),
              title: const Text(
                'Upload a selfie',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Choose a face-focused photo from your device',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted || photo == null) return;
      setState(() {
        _image = photo;
        _croppedFace = null;
        _error = null;
        _isAnalyzing = true;
      });
      widget.onFaceReady(null);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final faces = await _detector.processImage(
        InputImage.fromFilePath(photo.path),
      );
      if (faces.isEmpty) {
        return _finishWithError('No face found. Try a clear, well-lit photo.');
      }

      final decoded = img.decodeImage(await File(photo.path).readAsBytes());
      if (decoded == null) {
        return _finishWithError(
          'This photo could not be processed. Please try again.',
        );
      }
      // ML Kit applies EXIF rotation; decodeImage does not. Match them.
      final original = img.bakeOrientation(decoded);

      final face = faces
          .reduce(
            (a, b) =>
                a.boundingBox.width * a.boundingBox.height >=
                    b.boundingBox.width * b.boundingBox.height
                ? a
                : b,
          )
          .boundingBox;

      // Match the source scanner's centered square crop with a 15% margin.
      // Replicate border pixels when the square extends beyond the photo.
      final side = math.max(face.width, face.height) * 1.15;
      final cx = face.center.dx;
      final cy = face.center.dy;
      final left = (cx - side / 2).round();
      final top = (cy - side / 2).round();
      final cropSide = math.max(1, side.round());
      final crop = img.Image(width: cropSide, height: cropSide);
      for (var y = 0; y < cropSide; y++) {
        for (var x = 0; x < cropSide; x++) {
          final sourceX = (left + x).clamp(0, original.width - 1);
          final sourceY = (top + y).clamp(0, original.height - 1);
          crop.setPixel(x, y, original.getPixel(sourceX, sourceY));
        }
      }

      if (!mounted) return;
      setState(() {
        _croppedFace = crop;
        _isAnalyzing = false;
      });
      widget.onCaptureSource?.call(
        source == ImageSource.camera ? 'camera_selfie' : 'gallery_upload',
      );
      widget.onFaceReady(crop);
    } catch (e, st) {
      debugPrint('Face capture failed: $e\n$st');
      _finishWithError(
        source == ImageSource.camera
            ? 'Camera access failed. Check permission and try again.'
            : 'That photo could not be opened. Choose another selfie and try again.',
      );
    }
  }

  void _finishWithError(String message) {
    if (!mounted) return;
    setState(() {
      _croppedFace = null;
      _error = message;
      _isAnalyzing = false;
    });
    widget.onFaceReady(null);
  }

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Choose a live photo or upload a selfie for face analysis',
    child: GestureDetector(
      onTap: _isAnalyzing ? null : _showSourceOptions,
      child: Container(
        height: 445,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xff1E293B),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white10),
        ),
        child: _image == null ? _placeholder() : _photoPreview(),
      ),
    ),
  );

  Widget _photoPreview() => Stack(
    fit: StackFit.expand,
    children: [
      if (_image case final image?)
        Image.file(File(image.path), fit: BoxFit.cover)
      else
        _placeholder(),
      if (_isAnalyzing) const ColoredBox(color: Colors.black38),
      Positioned(top: 16, right: 16, child: _retakeButton()),
      Positioned(bottom: 20, left: 20, right: 20, child: _statusCard()),
    ],
  );

  Widget _retakeButton() => Material(
    color: Colors.black54,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: _isAnalyzing ? null : _showSourceOptions,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    ),
  );

  Widget _statusCard() {
    final ready = _croppedFace != null;
    final message = _isAnalyzing
        ? 'Analyzing face...'
        : ready
        ? 'Face ready for analysis'
        : _error ?? 'Take another photo to continue.';
    final color = ready ? const Color(0xff86EFAC) : const Color(0xffFDE68A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff0F172A).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (_isAnalyzing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff4EA8DE),
              ),
            )
          else
            Icon(
              ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.camera_alt_rounded, color: Color(0xff4EA8DE), size: 62),
      const SizedBox(height: 18),
      Text(
        'Tap to take a photo or upload a selfie',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Choose a clear, well-lit, face-focused image.',
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
      ),
    ],
  );
}
