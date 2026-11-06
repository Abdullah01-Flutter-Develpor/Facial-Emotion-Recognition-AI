import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo_app/features/emotion_result/models/emotion_analysis.dart';
import 'package:demo_app/core/services/chat_history_store.dart';

class AnalysisStore extends ChangeNotifier {
  static const _legacyStorageKey = 'emotion_analyses_v1';
  static const _storagePrefix = 'emotion_analyses_v2_';

  final List<EmotionAnalysis> _items = [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cloudSubscription;
  String? _userId;
  int _generation = 0;

  List<EmotionAnalysis> get items => List.unmodifiable(_items);
  EmotionAnalysis? get latest => _items.isEmpty ? null : _items.first;
  int get totalScans => _items.length;

  Future<void> load() async {
    await _changeUser(FirebaseAuth.instance.currentUser?.uid);
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen(
      (user) => unawaited(_changeUser(user?.uid)),
    );
  }

  CollectionReference<Map<String, dynamic>>? get _records {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('analyses');
  }

  Future<void> _changeUser(String? uid) async {
    if (_userId == uid && _cloudSubscription != null) return;
    final generation = ++_generation;
    await _cloudSubscription?.cancel();
    _cloudSubscription = null;
    _userId = uid;
    _items.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final key = uid == null ? '${_storagePrefix}local' : '$_storagePrefix$uid';
    var raw = prefs.getString(key);
    if (uid != null && raw == null) {
      // Migrate existing device-only history into the first signed-in profile.
      raw = prefs.getString(_legacyStorageKey);
      if (raw != null) await prefs.setString(key, raw);
    }
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items.addAll(
          decoded.map(
            (item) => EmotionAnalysis.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
        _sort();
      } catch (_) {
        await prefs.remove(key);
      }
    }
    if (generation != _generation) return;
    notifyListeners();

    final records = _records;
    if (records == null) return;
    _cloudSubscription = records
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            if (generation != _generation) return;
            final cloudItems = snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                data['createdAt'] = createdAt.toDate().toIso8601String();
              }
              return EmotionAnalysis.fromJson(data, id: doc.id);
            });
            final merged = <String, EmotionAnalysis>{};
            for (final item in [...cloudItems, ..._items]) {
              final key =
                  item.id ?? item.createdAt.microsecondsSinceEpoch.toString();
              merged.putIfAbsent(key, () => item);
            }
            _items
              ..clear()
              ..addAll(merged.values);
            _sort();
            notifyListeners();
            unawaited(_saveLocal());
          },
          onError: (Object error, StackTrace stack) {
            debugPrint('Could not sync emotion history: $error');
          },
        );
  }

  void _sort() => _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> add(EmotionAnalysis analysis) async {
    final records = _records;
    final saved = records == null
        ? EmotionAnalysis(
            id:
                analysis.id ??
                'local_${analysis.createdAt.microsecondsSinceEpoch}',
            emotion: analysis.emotion,
            confidence: analysis.confidence,
            scores: analysis.scores,
            createdAt: analysis.createdAt,
            captureSource: analysis.captureSource,
          )
        : EmotionAnalysis(
            id: records.doc().id,
            emotion: analysis.emotion,
            confidence: analysis.confidence,
            scores: analysis.scores,
            createdAt: analysis.createdAt,
            captureSource: analysis.captureSource,
          );
    _items.insert(0, saved);
    _sort();
    notifyListeners();
    try {
      await _saveLocal();
    } catch (error, stack) {
      // Keep the in-memory result available even if local persistence is not
      // available in a particular Android build or device state.
      debugPrint('Could not save emotion result locally: $error\n$stack');
    }
    if (records != null) {
      try {
        await records.doc(saved.id).set({
          'emotion': saved.emotion,
          'confidence': saved.confidence,
          'scores': saved.scores,
          'createdAt': Timestamp.fromDate(saved.createdAt.toUtc()),
          'model': 'fer2013_emotion_resnet18_v2_single',
          'source': 'on_device_face_expression_scan',
          'captureSource': saved.captureSource,
        });
      } catch (error) {
        // Keep the result available locally; Firestore will also queue writes
        // while offline on supported platforms.
        debugPrint('Could not save emotion result to Firestore: $error');
      }
    }
  }

  Future<void> clear() async {
    final records = _records;
    final uid = _userId;
    for (final item in List<EmotionAnalysis>.from(_items)) {
      await ChatHistoryStore.deleteForAnalysis(uid, item.id);
    }
    _items.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (records != null) {
      try {
        final snapshot = await records.get();
        for (var i = 0; i < snapshot.docs.length; i += 450) {
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in snapshot.docs.skip(i).take(450)) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (error) {
        debugPrint('Could not clear cloud emotion history: $error');
      }
    }
  }

  /// Delete exactly one analysis from local history and the signed-in user's
  /// Firestore collection. Firestore's offline queue keeps this operation
  /// available when the device temporarily has no connection.
  Future<void> delete(EmotionAnalysis analysis) async {
    final records = _records;
    await ChatHistoryStore.deleteForAnalysis(_userId, analysis.id);
    if (records != null && analysis.id != null) {
      unawaited(_deleteCloudRecord(records.doc(analysis.id)));
    }
    _items.removeWhere(
      (item) => analysis.id != null
          ? item.id == analysis.id
          : identical(item, analysis),
    );
    notifyListeners();
    await _saveLocal();
  }

  Future<void> _deleteCloudRecord(
    DocumentReference<Map<String, dynamic>> record,
  ) async {
    try {
      await record.delete();
    } catch (error) {
      debugPrint('Could not delete emotion record from Firestore: $error');
    }
  }

  String get _storageKey => '$_storagePrefix${_userId ?? 'local'}';

  Future<void> _saveLocal() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
  }

  String? get mostCommonEmotion {
    if (_items.isEmpty) return null;
    final counts = <String, int>{};
    for (final item in _items) {
      counts.update(item.emotion, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double get positiveMoodPercent {
    if (_items.isEmpty) return 0;
    return _items.where((item) => item.isPositive).length / _items.length * 100;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_cloudSubscription?.cancel());
    super.dispose();
  }
}
