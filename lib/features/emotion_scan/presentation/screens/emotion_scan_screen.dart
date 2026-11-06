import 'package:demo_app/ml/emotion_classifier.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import 'package:demo_app/features/emotion_result/presentation/screens/emotion_result_screen.dart';
import 'package:demo_app/features/emotion_scan/presentation/widgets/camera_preview_placeholder.dart';

class EmotionScanScreen extends StatefulWidget {
  const EmotionScanScreen({super.key});

  @override
  State<EmotionScanScreen> createState() => _EmotionScanScreenState();
}

class _EmotionScanScreenState extends State<EmotionScanScreen> {
  final _classifier = EmotionClassifier();
  img.Image? _face;
  String _captureSource = 'unknown';
  bool _busy = false;

  Future<void> _startScan() async {
    if (_busy) return;
    final face = _face;
    if (face == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Take a clear photo with one visible face first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final prediction = await _classifier.predict(face);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmotionResultScreen(
            prediction: prediction,
            captureSource: _captureSource,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Emotion analysis failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'We could not analyze this photo. Please try a clearer selfie.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff0F172A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: Text(
        'Emotion Scan',
        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let AI understand your expression',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Position your face clearly and take a photo to prepare your scan.',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 28),
            CameraPreviewPlaceholder(
              onFaceReady: (face) {
                if (!mounted) return;
                setState(() => _face = face);
              },
              onCaptureSource: (source) {
                if (!mounted) return;
                setState(() => _captureSource = source);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _startScan,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _busy ? 'Analyzing...' : 'Start Emotion Scan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Photos are processed on your device. No image is saved to scan history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
