// ignore_for_file: use_build_context_synchronously
import 'package:demo_app/core/services/auth_service.dart';
import 'package:demo_app/features/auth/auth_option_screen.dart';
import 'package:demo_app/features/auth/forgot_password.dart';
import 'package:demo_app/features/auth/sign_in_screen.dart';
import 'package:demo_app/features/auth/sign_up_screen.dart';
import 'package:demo_app/features/history/history_screen.dart';
import 'package:demo_app/features/chat/emotion_chat_screen.dart';
import 'package:demo_app/features/insight/insight_screen.dart';
import 'package:demo_app/features/profile/widgets/about_screen.dart';
import 'package:demo_app/features/profile/widgets/edit_profile.dart';
import 'package:demo_app/ml/emotion_classifier.dart';
import 'package:flutter/material.dart';

import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/emotion_scan/emotion_scan.dart';
import '../features/emotion_result/emotion_result_screen.dart';
import '../features/profile/settings_screen.dart';

import 'app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.onboarding: (_) => const OnboardingScreen(),
    AppRoutes.home: (_) => const HomeScreen(),
    AppRoutes.scan: (_) => const EmotionScanScreen(),
    AppRoutes.emotionResult: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is EmotionPrediction) {
        return EmotionResultScreen(prediction: args);
      }
      // No prediction supplied: send the user back to scanning.
      return const EmotionScanScreen();
    },
    AppRoutes.settings: (_) => const SettingsScreen(),
    AppRoutes.history: (_) => const HistoryScreen(),
    AppRoutes.insights: (_) => const InsightsScreen(),
    AppRoutes.emotionChat: (_) => const EmotionChatScreen(),
    AppRoutes.editProfile: (_) => const EditProfileScreen(),
    AppRoutes.about: (_) => const AboutScreen(),

    AppRoutes.authOptions: (context) => AuthOptionsScreen(
      onGoogle: () async {
        final error = await AuthService.instance.signInWithGoogle();
        if (!context.mounted) return;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      },
      onEmail: () => Navigator.of(context).pushNamed(AppRoutes.signUp),
    ),

    AppRoutes.signIn: (context) => SignInScreen(
      initialEmail: ModalRoute.of(context)?.settings.arguments as String?,
      onSignIn: (email, password) async {
        final error = await AuthService.instance.signIn(email, password);
        if (error != null) return error;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        return null;
      },
      onForgotPassword: () {
        Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
      },
      onCreateAccount: () {
        Navigator.of(context).pushNamed(AppRoutes.signUp);
      },
    ),

    AppRoutes.signUp: (context) => SignUpScreen(
      onSignUp: AuthService.instance.signUp,
      onAccountCreated: (email) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (route) => false,
          arguments: email,
        );
      },
      onSignIn: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
    ),

    AppRoutes.forgotPassword: (context) => ForgotPasswordScreen(
      onSendCode: AuthService.instance.sendPasswordResetEmail,
      onCodeSent: (email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for a reset link.')),
        );
        Navigator.of(context).pop();
      },
      onBackToSignIn: () => Navigator.of(context).pop(),
    ),
  };
}
