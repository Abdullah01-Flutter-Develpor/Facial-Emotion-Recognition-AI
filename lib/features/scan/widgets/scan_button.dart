import 'package:flutter/material.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.face_retouching_natural_rounded),
      label: Text(loading ? 'Analyzing...' : 'Analyze Emotion'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff3B82F6),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xff1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}