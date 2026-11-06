import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final _picker = ImagePicker();
  bool _uploading = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _pickAndUpload(ImageSource source) async {
    final uid = _uid;
    if (uid == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 640,
    );
    if (file == null) return;

    setState(() => _uploading = true);

    try {
      final Uint8List bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'photoBase64': base64Image,
          'photoUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload photo. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'photoBase64': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _removePhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: uid == null
                ? null
                : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              final base64Image = snapshot.data?.data()?['photoBase64'] as String?;

              return CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xff5E60CE),
                backgroundImage:
                    base64Image != null ? MemoryImage(base64Decode(base64Image)) : null,
                child: base64Image == null
                    ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                    : null,
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xff3B82F6),
              shape: BoxShape.circle,
            ),
            child: _uploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.edit, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}