import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:demo_app/features/onboarding/models/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel page;

  const OnboardingPage({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            SizedBox(height: size.height * 0.02),

            // Animation Container
            SizedBox(
              height: size.height * 0.42,
              width: double.infinity,
              child: Center(
                child: Lottie.asset(
                  page.animation,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  frameRate: FrameRate.max,

                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.animation,
                      size: 150,
                      color: Colors.white24,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade400,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}