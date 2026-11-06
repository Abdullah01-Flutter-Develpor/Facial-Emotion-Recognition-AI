import 'package:flutter/material.dart';

import 'package:demo_app/core/services/ai_chat_diagnostics.dart';

class AiChatActivityScreen extends StatefulWidget {
  const AiChatActivityScreen({super.key});

  @override
  State<AiChatActivityScreen> createState() => _AiChatActivityScreenState();
}

class _AiChatActivityScreenState extends State<AiChatActivityScreen> {
  late Future<List<Map<String, dynamic>>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = AiChatDiagnostics.read();
  }

  Future<void> _clear() async {
    await AiChatDiagnostics.clear();
    if (!mounted) return;
    setState(() => _entries = AiChatDiagnostics.read());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff0F172A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('AI chat activity'),
      actions: [
        IconButton(
          tooltip: 'Clear activity',
          onPressed: _clear,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _entries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Text(
              'Loading activity…',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No chat activity yet. Request times and connection errors will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final time = DateTime.tryParse(entry['at'] as String? ?? '');
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['event'] as String? ?? 'Activity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry['detail'] is String) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry['detail'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      time.toLocal().toString().substring(0, 19),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
