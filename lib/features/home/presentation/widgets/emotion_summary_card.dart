import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:demo_app/core/state/analysis_scope.dart';

class EmotionSummaryCard extends StatelessWidget {
  const EmotionSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final latest = AnalysisScope.of(context).latest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xff4EA8DE),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Latest Expression',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (latest == null)
            Text(
              'No result yet. Run your first emotion scan to see it here.',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            )
          else
            Row(
              children: [
                Text(latest.emoji, style: const TextStyle(fontSize: 42)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest.emotion,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Latest detected expression',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(latest.confidence * 100).round()}%',
                  style: GoogleFonts.poppins(
                    color: const Color(0xff4EA8DE),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
