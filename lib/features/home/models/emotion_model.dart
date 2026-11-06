import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/analysis_scope.dart';
import '../../features/emotion_result/models/emotion_analysis.dart';
import '../emotion_result/analysis_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AnalysisScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'History',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: store.items.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: store.items.length,
              itemBuilder: (context, index) {
                final item = store.items[index];
                return _HistoryTile(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AnalysisDetailScreen(analysis: item),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, item),
                );
              },
            ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved analyses yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your results will appear here after your first emotion scan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    EmotionAnalysis item,
  ) async {
    final store = AnalysisScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1E293B),
        title: const Text(
          'Delete this analysis?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Only this selected result will be removed from this device and your account.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xffFCA5A5)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.delete(item);
    } catch (error) {
      debugPrint('Could not delete selected analysis: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this analysis. Please try again.'),
          ),
        );
      }
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final EmotionAnalysis item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (sourceLabel, sourceIcon) = switch (item.captureSource) {
      'camera_selfie' => ('Camera selfie', Icons.camera_alt_outlined),
      'gallery_upload' => ('Uploaded photo', Icons.photo_library_outlined),
      _ => ('Older scan', Icons.help_outline_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
          child: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.emotion[0].toUpperCase() + item.emotion.substring(1),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_formatDate(context, item.createdAt)} · ${(item.confidence * 100).round()}% score',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff4EA8DE).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sourceIcon,
                            size: 12,
                            color: const Color(0xff93C5FD),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            sourceLabel,
                            style: GoogleFonts.poppins(
                              color: const Color(0xffBFDBFE),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete this analysis',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white54,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) =>
      '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}';
}
