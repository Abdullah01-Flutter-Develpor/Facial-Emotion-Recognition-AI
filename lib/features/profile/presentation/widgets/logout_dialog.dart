import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/core/services/auth_service.dart';
import 'package:demo_app/core/services/chat_history_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/app/app_routes.dart';

Future<void> showLogoutDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xff1E293B),
      title: const Text('Account', style: TextStyle(color: Colors.white)),
      content: const Text(
        'What would you like to do?',
        style: TextStyle(color: Colors.white60),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await AuthService.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authOptions,
                (route) => false,
              );
            }
          },
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _confirmDelete(context);
          },
          child: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xff1E293B),
      title: const Text(
        'Delete account?',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'This permanently deletes your account and all your data. This cannot be undone.',
        style: TextStyle(color: Colors.white60),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _deleteAccount(context),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteAccount(BuildContext context) async {
  Navigator.pop(context);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;

  try {
    await ChatHistoryStore.deleteAllForUser(uid);
    final analyses = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('analyses');
    while (true) {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await analyses.limit(450).get();
      if (snapshot.docs.isEmpty) break;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) =>
          key == 'emotion_analyses_v1' ||
          key.startsWith('emotion_analyses_v2_'),
    )) {
      await preferences.remove(key);
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    await user.delete();

    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.authOptions, (route) => false);
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'For security, please log out and log back in, then try deleting again.',
            ),
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not delete account.')),
      );
    }
  }
}
