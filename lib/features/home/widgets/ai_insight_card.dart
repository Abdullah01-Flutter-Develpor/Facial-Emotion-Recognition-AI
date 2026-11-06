import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../chat/emotion_chat_screen.dart';

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xff4EA8DE).withValues(alpha: .15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xff5E60CE).withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xff4EA8DE),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Your saved expression estimates can offer a moment to reflect. '
                  'Open chat for practical, supportive ideas. ✨',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.psychology_rounded,
                      size: 16,
                      color: Color(0xff4EA8DE),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Powered by EmoSense AI',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EmotionChatScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Open supportive chat'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff93C5FD),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    textStyle: GoogleFonts.poppins(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
