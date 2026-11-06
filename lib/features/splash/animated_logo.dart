// ignore_for_file: unused_field, deprecated_member_use

import 'package:demo_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';


class AnimatedLogo extends StatefulWidget {
  final double size;
  final IconData icon;

  const AnimatedLogo({
    super.key,
    this.size = 130,
    this.icon = Icons.psychology_alt_rounded,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 1, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, entranceValue, child) {
        return Transform.scale(
          scale: entranceValue,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size * 1.8,
            height: widget.size * 1.8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * _pulse.value * 1.6,
                  height: widget.size * _pulse.value * 1.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(_glowOpacity.value * 0.35),
                        AppColors.primary.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: widget.size * _pulse.value,
                  height: widget.size * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDeep, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(_glowOpacity.value),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.5,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
