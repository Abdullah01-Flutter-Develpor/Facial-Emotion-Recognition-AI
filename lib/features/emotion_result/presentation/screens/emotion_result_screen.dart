import 'package:demo_app/core/state/analysis_scope.dart';
import 'package:demo_app/features/emotion_result/models/emotion_analysis.dart';
import 'package:demo_app/ml/emotion_classifier.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionResultScreen extends StatefulWidget {
  const EmotionResultScreen({
    super.key,
    required this.prediction,
    this.captureSource = 'unknown',
  });

  final EmotionPrediction prediction;
  final String captureSource;

  @override
  State<EmotionResultScreen> createState() => _EmotionResultScreenState();
}

class _EmotionResultScreenState extends State<EmotionResultScreen> {
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saved) return;
    _saved = true;
    AnalysisScope.of(context).add(
      EmotionAnalysis(
        emotion: widget.prediction.label,
        confidence: widget.prediction.confidence,
        scores: widget.prediction.scores,
        createdAt: DateTime.now(),
        captureSource: widget.captureSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prediction = widget.prediction;
    final sorted = prediction.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final low = prediction.confidence < 0.5;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Emotion Result',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              prediction.label.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(prediction.confidence * 100).toStringAsFixed(1)}% confidence',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xff4EA8DE)),
            ),
            if (low)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Low confidence. Try a clearer, front-facing photo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xffFDE68A),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            for (final e in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: e.value,
                          minHeight: 10,
                          backgroundColor: const Color(0xff1E293B),
                          color: const Color(0xff4EA8DE),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${(e.value * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Scan'),
            ),
          ],
        ),
      ),
    );
  }
}
