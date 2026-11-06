import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlowBadge extends StatelessWidget {
  final IconData icon;

  const GlowBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.white, size: 32),
    );
  }
}