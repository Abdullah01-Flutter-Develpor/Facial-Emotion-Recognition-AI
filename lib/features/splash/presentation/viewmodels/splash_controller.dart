import 'dart:async';

import 'package:demo_app/app/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashController {
  void start(BuildContext context) {
    Timer(
      const Duration(seconds: 2),
      () {
        final user = FirebaseAuth.instance.currentUser;

        final nextRoute = user == null
            ? AppRoutes.onboarding // not signed in -> onboarding -> sign in/up
            : AppRoutes.home; // already signed in -> straight to home

        Navigator.pushReplacementNamed(
          context,
          nextRoute,
        );
      },
    );
  }
}