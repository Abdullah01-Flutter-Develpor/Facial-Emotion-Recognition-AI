import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores one Home conversation and one separate conversation per analysis.
class ChatHistoryStore {
  ChatHistoryStore({required this.analysisId})
    : _uid = FirebaseAuth.instance.currentUser?.uid;

  final String? analysisId;
  final String? _uid;

  String get conversationId =>
      analysisId == null ? 'home' : 'analysis_$analysisId';
  String get _cacheKey => 'emotion_chat_v1_${_uid ?? 'local'}_$conversationId';

  CollectionReference<Map<String, dynamic>>? get _messages => _uid == null
      ? null
      : FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('chats')
            .doc(conversationId)
            .collection('messages');

  Future<List<Map<String, dynamic>>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_cacheKey);
    if (raw == null && _uid != null) {
      final localKey = 'emotion_chat_v1_local_$conversationId';
      raw = prefs.getString(localKey);
      if (raw != null) {
        await prefs.setString(_cacheKey, raw);
        await prefs.remove(localKey);
      }
    }
    return _decode(raw);
  }

  Future<List<Map<String, dynamic>>> syncCloud() async {
    final messages = _messages;
    if (messages == null) return loadLocal();
    try {
      final snapshot = await messages.orderBy('createdAt').get();
      final merged = <String, Map<String, dynamic>>{};
      // Re-read after the network request so messages sent during this sync
      // are included instead of being overwritten by an older local snapshot.
      final latestLocal = await loadLocal();
      for (final item in latestLocal) {
        merged[item['id'] as String] = item;
      }
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;
        final date = data['createdAt'];
        if (date is Timestamp) {
          data['createdAt'] = date.toDate().toIso8601String();
        }
        merged[doc.id] = data;
      }
      final result = merged.values.toList()
        ..sort(
          (a, b) =>
              (a['createdAt'] as String).compareTo(b['createdAt'] as String),
        );
      await _save(result);
      // A prior offline local message may not have reached Firestore yet.
      for (final item in result) {
        if (!snapshot.docs.any((doc) => doc.id == item['id'])) {
          await messages.doc(item['id'] as String).set(_cloudData(item));
        }
      }
      return result;
    } catch (error) {
      debugPrint('Could not load chat history from Firestore: $error');
      return loadLocal();
    }
  }

  Future<void> add(
    String role,
    String text, {
    bool localFallback = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _decode(prefs.getString(_cacheKey));
    final id = '${DateTime.now().microsecondsSinceEpoch}_${all.length}';
    final message = <String, dynamic>{
      'id': id,
      'role': role,
      'text': text,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'localFallback': localFallback,
    };
    all.add(message);
    await _save(all);
    final messages = _messages;
    if (messages != null) {
      unawaited(_writeCloud(messages, message));
    }
  }

  Future<void> _writeCloud(
    CollectionReference<Map<String, dynamic>> messages,
    Map<String, dynamic> message,
  ) async {
    try {
      await messages.doc(message['id'] as String).set(_cloudData(message));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('chats')
          .doc(conversationId)
          .set({
            'scope': analysisId == null ? 'home' : 'analysis',
            'analysisId': analysisId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      // SharedPreferences keeps the conversation available for later sync.
      debugPrint('Could not save chat message to Firestore: $error');
    }
  }

  Future<void> _save(List<Map<String, dynamic>> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(all));
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _cloudData(Map<String, dynamic> item) => {
    'role': item['role'],
    'text': item['text'],
    'createdAt': Timestamp.fromDate(
      DateTime.parse(item['createdAt'] as String),
    ),
    'localFallback': item['localFallback'] == true,
  };

  static Future<void> deleteForAnalysis(String? uid, String? analysisId) async {
    if (analysisId == null) return;
    final chatId = 'analysis_$analysisId';
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'emotion_chat_v1_${uid ?? 'local'}_$chatId';
    final localKey = 'emotion_chat_v1_local_$chatId';
    final localMessages = <Map<String, dynamic>>[
      ..._decodeRaw(prefs.getString(cacheKey)),
      if (uid != null) ..._decodeRaw(prefs.getString(localKey)),
    ];
    await prefs.remove(cacheKey);
    if (uid != null) await prefs.remove(localKey);
    if (uid != null) {
      unawaited(_deleteCloudChat(uid, chatId, localMessages));
    }
  }

  static Future<void> _deleteCloudChat(
    String uid,
    String chatId,
    List<Map<String, dynamic>> localMessages,
  ) async {
    try {
      final chat = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId);
      final knownIds = <String>{
        for (final item in localMessages)
          if (item['id'] is String) item['id'] as String,
      };
      // Query while online to catch messages newer than the local cache.
      try {
        final snapshot = await chat.collection('messages').get();
        knownIds.addAll(snapshot.docs.map((doc) => doc.id));
      } catch (error) {
        debugPrint('Using cached chat IDs for offline cleanup: $error');
      }
      final ids = knownIds.toList();
      for (var i = 0; i < ids.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        for (final id in ids.skip(i).take(450)) {
          batch.delete(chat.collection('messages').doc(id));
        }
        await batch.commit();
      }
      await chat.delete();
    } catch (error) {
      // Local cache is already removed, and Firestore will retry queued writes
      // if the connection was temporarily unavailable.
      debugPrint('Could not finish cloud cleanup for analysis chat: $error');
    }
  }

  static List<Map<String, dynamic>> _decodeRaw(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteAllForUser(String uid) async {
    final chats = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats');
    while (true) {
      final snapshot = await chats.limit(100).get();
      if (snapshot.docs.isEmpty) break;
      for (final chat in snapshot.docs) {
        while (true) {
          final messages = await chat.reference
              .collection('messages')
              .limit(450)
              .get();
          if (messages.docs.isEmpty) break;
          final batch = FirebaseFirestore.instance.batch();
          for (final message in messages.docs) {
            batch.delete(message.reference);
          }
          await batch.commit();
        }
        await chat.reference.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(
      (key) => key.startsWith('emotion_chat_v1_'),
    )) {
      await prefs.remove(key);
    }
  }
}
