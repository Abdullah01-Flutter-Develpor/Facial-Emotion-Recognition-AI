import 'package:animate_do/animate_do.dart';
import 'package:demo_app/features/splash/animated_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

import 'splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashController controller = SplashController();

  @override
  void initState() {
    super.initState();
    controller.start(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedLogo(size: 110),

              const SizedBox(height: 25),

              FadeInUp(
                duration: const Duration(milliseconds: 900),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  "EmoSense AI",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              FadeInUp(
                duration: const Duration(milliseconds: 900),
                delay: const Duration(milliseconds: 450),
                child: Text(
                  "Understand Emotions\nThrough Artificial Intelligence",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              FadeIn(
                duration: const Duration(milliseconds: 900),
                delay: const Duration(milliseconds: 700),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}