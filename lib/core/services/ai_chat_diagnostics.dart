import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores local AI request timings and outcomes without recording chat content.
class AiChatDiagnostics {
  static const _key = 'ai_chat_diagnostics_v1';

  static Future<void> record(String event, {String? detail}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final entries = _decode(preferences.getString(_key));
      entries.add({
        'at': DateTime.now().toIso8601String(),
        'event': event,
        'detail': ?detail,
      });
      if (entries.length > 100) entries.removeRange(0, entries.length - 100);
      await preferences.setString(_key, jsonEncode(entries));
    } catch (_) {
      // Diagnostics must never interrupt a chat reply.
    }
  }

  static Future<List<Map<String, dynamic>>> read() async {
    final preferences = await SharedPreferences.getInstance();
    return _decode(preferences.getString(_key)).reversed.toList();
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }

  static List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
