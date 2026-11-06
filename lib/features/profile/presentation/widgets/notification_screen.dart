import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _weeklySummary = false;
  bool _loading = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final prefs = snap.data()?['notificationPrefs'] as Map<String, dynamic>?;
    if (mounted) {
      setState(() {
        _pushEnabled = prefs?['push'] ?? true;
        _emailEnabled = prefs?['email'] ?? true;
        _weeklySummary = prefs?['weeklySummary'] ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _update(String key, bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'notificationPrefs': {key: value},
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff3B82F6)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _toggle(
                  'Push Notifications',
                  'Get notified when a scan finishes',
                  _pushEnabled,
                  (v) {
                    setState(() => _pushEnabled = v);
                    _update('push', v);
                  },
                ),
                _toggle(
                  'Email Updates',
                  'Product updates and feature announcements',
                  _emailEnabled,
                  (v) {
                    setState(() => _emailEnabled = v);
                    _update('email', v);
                  },
                ),
                _toggle(
                  'Weekly Insights Summary',
                  'A recap of your emotion trends each week',
                  _weeklySummary,
                  (v) {
                    setState(() => _weeklySummary = v);
                    _update('weeklySummary', v);
                  },
                ),
              ],
            ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          activeThumbColor: const Color(0xff3B82F6),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}