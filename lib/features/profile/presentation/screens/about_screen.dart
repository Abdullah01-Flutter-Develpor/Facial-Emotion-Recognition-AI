import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'About EmoSense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff8B5CF6), Color(0xff3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'EmoSense AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Version 1.0.0', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          const Text(
            'EmoSense AI detects and analyzes facial expressions using an on-device model, giving users a way to review expression labels over time. These estimates cannot determine a person’s actual feelings and are not a diagnosis.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'About these insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            title: 'FER-2013 research reference',
            body:
                'Goodfellow et al. (2013) report a 60% convolutional “null” baseline and a 71.162% winning score on the FER-2013 private test set. The paper also estimated human accuracy on FER-2013 at 65% ± 5%. These are results from different evaluations and systems; they are not a measured accuracy range for EmoSense AI.',
            footnote:
                'Goodfellow et al., “Challenges in Representation Learning: A Report on Three Machine Learning Contests,” ICML 2013 workshop report, arXiv:1307.0414.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            title: 'Understanding model scores',
            body:
                'A 50% score means the model assigned 0.50 to its top expression label for that image. There is no universal “good” cutoff: the score is not calibrated and does not mean there is a 50% chance that the person feels that way. A clear, well-lit, front-facing photo may produce a more useful estimate. Charts summarize saved model labels; they are not a diagnosis.',
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String body,
    String? footnote,
  }) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xff1E293B),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 8),
          Text(
            footnote,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}
