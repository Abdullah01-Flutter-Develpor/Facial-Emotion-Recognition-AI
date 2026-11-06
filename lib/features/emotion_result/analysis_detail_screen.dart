import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/emotion_result/models/emotion_analysis.dart';
import '../chat/emotion_chat_screen.dart';

class AnalysisDetailScreen extends StatelessWidget {
  const AnalysisDetailScreen({super.key, required this.analysis});
  final EmotionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final scores = analysis.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final source = switch (analysis.captureSource) {
      'camera_selfie' => 'Camera selfie',
      'gallery_upload' => 'Uploaded photo',
      _ => 'Older scan · source unavailable',
    };
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Analysis detail',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xff1E293B),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(analysis.emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 8),
                Text(
                  _titleCase(analysis.emotion),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${(analysis.confidence * 100).toStringAsFixed(1)}% model score',
                  style: GoogleFonts.poppins(
                    color: const Color(0xff60A5FA),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'This is the model’s score for its top expression label. It is not a measure of your actual feelings or the model’s overall test accuracy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _section(
            'Scan details',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.schedule_rounded,
                  'Saved',
                  '${MaterialLocalizations.of(context).formatFullDate(analysis.createdAt)} · ${TimeOfDay.fromDateTime(analysis.createdAt).format(context)}',
                ),
                const SizedBox(height: 12),
                _detailRow(
                  analysis.captureSource == 'camera_selfie'
                      ? Icons.camera_alt_outlined
                      : Icons.photo_library_outlined,
                  'Photo source',
                  source,
                ),
              ],
            ),
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 18),
            _section(
              'Expression scores',
              Column(
                children: [
                  for (final entry in scores) _scoreBar(entry.key, entry.value),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _section(
            'A gentle next step',
            Text(
              _suggestion(analysis.emotion),
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => EmotionChatScreen(analysis: analysis),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ask AI for supportive ideas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Facial-expression estimates are imperfect and are not a diagnosis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff1E293B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xff60A5FA)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          '$label  ·  $value',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _scoreBar(String label, double value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            _titleCase(label),
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 9,
              backgroundColor: const Color(0xff0F172A),
              color: const Color(0xff4EA8DE),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            '${(value * 100).toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _suggestion(String emotion) => switch (emotion.toLowerCase()) {
    'happy' =>
      'If this expression matches how you feel, take a moment to notice what has been going well and enjoy it. You could share that positive moment with someone you trust.',
    'sad' =>
      'If you are feeling low, consider a small, kind step such as taking a break, getting some water, or checking in with someone you trust. You can ignore this suggestion if it does not fit.',
    'angry' =>
      'If you feel tense, a brief pause or slow breathing may help create room to decide what you need next. This expression estimate may also be wrong.',
    'fear' =>
      'If you feel worried, try grounding yourself by noticing a few things around you and consider talking with someone you trust.',
    'disgust' =>
      'If something feels uncomfortable, give yourself space and consider what would help you feel more at ease.',
    'surprise' =>
      'If something unexpected happened, take a moment to pause and decide whether you want to explore it further.',
    _ =>
      'If this neutral-looking expression matches your experience, you might use this moment to check in with yourself. The estimate does not determine how you feel.',
  };
}
