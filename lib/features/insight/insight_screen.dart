import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/analysis_scope.dart';

const _emotions = [
  'happy',
  'neutral',
  'sad',
  'angry',
  'fear',
  'surprise',
  'disgust',
];
const _blue = Color(0xff60A5FA);

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AnalysisScope.of(context).items;
    final counts = {for (final emotion in _emotions) emotion: 0};
    for (final item in items) {
      counts.update(
        item.emotion.toLowerCase(),
        (value) => value + 1,
        ifAbsent: () => 0,
      );
    }
    final week = List.generate(7, (offset) {
      final date = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: 6 - offset)),
      );
      final count = items
          .where((item) => DateUtils.isSameDay(item.createdAt.toLocal(), date))
          .length;
      return (date: date, count: count);
    });
    final camera = items
        .where((item) => item.captureSource == 'camera_selfie')
        .length;
    final gallery = items
        .where((item) => item.captureSource == 'gallery_upload')
        .length;
    final older = items.length - camera - gallery;
    final average = items.isEmpty
        ? 0.0
        : items.map((item) => item.confidence).reduce((a, b) => a + b) /
              items.length;
    final maxEmotionCount = counts.values.fold<int>(1, (a, b) => a > b ? a : b);
    final maxDayCount = week
        .map((day) => day.count)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Insights',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Your Emotional Insights',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Patterns in your saved facial-expression estimates.',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.analytics_outlined,
                  'All scans',
                  '${items.length}',
                  'Saved records',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.auto_graph_rounded,
                  'Most common',
                  items.isEmpty
                      ? '—'
                      : _titleCase(
                          counts.entries
                              .reduce((a, b) => a.value >= b.value ? a : b)
                              .key,
                        ),
                  items.isEmpty
                      ? 'No data yet'
                      : '${counts.values.fold<int>(0, (a, b) => a + b)} scans total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _chartCard(
            title: 'Scans over the last 7 days',
            subtitle:
                'Number of saved analyses each day · ${week.fold<int>(0, (sum, day) => sum + day.count)} this week',
            child: _weekChart(week, maxDayCount),
          ),
          const SizedBox(height: 16),
          _chartCard(
            title: 'Expression distribution',
            subtitle: 'Counts from ${items.length} saved analyses',
            child: items.isEmpty
                ? _chartEmpty('Your chart will appear after your first scan.')
                : Column(
                    children: [
                      for (final emotion in _emotions)
                        _distributionRow(
                          emotion,
                          counts[emotion]!,
                          maxEmotionCount,
                          items.length,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _chartCard(
            title: 'Photo source',
            subtitle: 'How saved scans were captured',
            child: items.isEmpty
                ? _chartEmpty('No photo sources to show yet.')
                : Column(
                    children: [
                      _sourceRow(
                        Icons.camera_alt_outlined,
                        'Camera selfie',
                        camera,
                        items.length,
                        const Color(0xff60A5FA),
                      ),
                      _sourceRow(
                        Icons.photo_library_outlined,
                        'Uploaded photo',
                        gallery,
                        items.length,
                        const Color(0xffA78BFA),
                      ),
                      _sourceRow(
                        Icons.help_outline_rounded,
                        'Older / unknown source',
                        older,
                        items.length,
                        const Color(0xff94A3B8),
                      ),
                    ],
                  ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            _chartCard(
              title: 'Average top-expression score',
              subtitle:
                  'Across ${items.length} results · a model output score, not accuracy',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(average * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color: _blue,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'mean top score',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: average.clamp(0, 1),
                      minHeight: 10,
                      color: _blue,
                      backgroundColor: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'The model’s score describes how strongly its output favored one label. It is not calibrated likelihood, benchmark accuracy, or a measure of how you really feel.',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    String footnote,
  ) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xff1E293B),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _blue, size: 19),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          footnote,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9),
        ),
      ],
    ),
  );

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Container(
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _weekChart(List<({DateTime date, int count})> days, int maxCount) {
    return Semantics(
      label: 'Bar chart of saved scans for each of the last seven days',
      child: SizedBox(
        height: 124,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day.count}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (76.0 * day.count / maxCount)
                            .clamp(5.0, 76.0)
                            .toDouble(),
                        decoration: BoxDecoration(
                          color: _blue.withValues(
                            alpha: day.count == 0 ? .2 : .85,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.date.weekday -
                            1],
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _distributionRow(String emotion, int count, int maxCount, int total) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(
                _titleCase(emotion),
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: count / maxCount,
                  minHeight: 9,
                  color: _emotionColor(emotion),
                  backgroundColor: const Color(0xff0F172A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              child: Text(
                '$count · ${(count * 100 / total).round()}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
              ),
            ),
          ],
        ),
      );

  Widget _sourceRow(
    IconData icon,
    String label,
    int count,
    int total,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          ),
        ),
        Text(
          '$count / $total',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _chartEmpty(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      message,
      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
    ),
  );

  String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
  Color _emotionColor(String emotion) => switch (emotion) {
    'happy' => const Color(0xff34D399),
    'neutral' => const Color(0xff60A5FA),
    'sad' => const Color(0xff818CF8),
    'angry' => const Color(0xffF87171),
    'fear' => const Color(0xffA78BFA),
    'surprise' => const Color(0xffFBBF24),
    _ => const Color(0xffFB923C),
  };
}
