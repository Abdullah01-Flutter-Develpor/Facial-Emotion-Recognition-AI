import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanCameraCard extends StatefulWidget {
  const ScanCameraCard({super.key});

  @override
  State<ScanCameraCard> createState() => _ScanCameraCardState();
}

class _ScanCameraCardState extends State<ScanCameraCard> {
  XFile? image;
  final picker = ImagePicker();

  Future<void> takePhoto() async {
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) return;

    setState(() {
      image = photo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: takePhoto,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xff1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
        ),
        child: image == null
            ? _placeholder()
            : ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(image!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(35),
                        child: CustomPaint(
                          painter: _ScanFramePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white24,
          size: 70,
        ),

        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(35),
            child: CustomPaint(
              painter: _ScanFramePainter(),
            ),
          ),
        ),

        Positioned(
          bottom: 25,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Tap to open camera',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff4EA8DE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * .15,
      size.height * .18,
      size.width * .7,
      size.height * .64,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(30),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}