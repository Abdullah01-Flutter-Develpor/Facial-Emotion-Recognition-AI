import 'package:demo_app/features/emotion_result/emotion_result_screen.dart';
import 'package:demo_app/features/emotion_scan/widgets/camera_preview_placeholder.dart';
import 'package:demo_app/ml/emotion_classifier.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import 'widgets/scan_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _classifier = EmotionClassifier();
  img.Image? _face;
  bool _busy = false;
  String? _error;

  Future<void> _analyze() async {
    final face = _face;
    if (face == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prediction = await _classifier.predict(face);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmotionResultScreen(prediction: prediction),
        ),
      );
    } catch (e, stack) {
      debugPrint('Emotion analysis failed: $e\n$stack');
      if (mounted) {
        setState(() => _error = 'Could not analyze this photo. Try again.');
      }
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
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Let AI understand your emotion',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a clear, well-lit photo with one face.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            CameraPreviewPlaceholder(
              onFaceReady: (f) => setState(() => _face = f),
            ),
            const SizedBox(height: 20),
            ScanButton(
              loading: _busy,
              onPressed: _face == null || _busy ? null : _analyze,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xffFDE68A),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Photos are analyzed on your device.',
              style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}
