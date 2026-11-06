import 'package:demo_app/core/theme/app_colors.dart';
import 'package:demo_app/core/theme/glow.dart';
import 'package:demo_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:demo_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Future<String?> Function(String email)? onSendCode;
  final void Function(String email)? onCodeSent;
  final VoidCallback? onBackToSignIn;

  const ForgotPasswordScreen({
    super.key,
    this.onSendCode,
    this.onCodeSent,
    this.onBackToSignIn,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    String? errorMessage;
    if (widget.onSendCode != null) {
      errorMessage = await widget.onSendCode!(email);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      widget.onCodeSent?.call(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                onPressed: widget.onBackToSignIn,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: GlowBadge(icon: Icons.mail_lock_outlined)),
                        const SizedBox(height: 28),
                        Text('Forgot password?',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          "Enter your email and we'll send you a code to reset it",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 32),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 28),
                        AuthButton(
                          label: 'Send Code',
                          isLoading: _isLoading,
                          onPressed: _handleSendCode,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Remembered it?',
                                style: Theme.of(context).textTheme.bodyMedium),
                            TextButton(
                              onPressed: widget.onBackToSignIn,
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ],
                    ),
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