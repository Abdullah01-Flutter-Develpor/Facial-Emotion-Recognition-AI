import 'package:demo_app/core/theme/app_colors.dart';
import 'package:demo_app/core/theme/glow.dart';
import 'package:demo_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:demo_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';


class ResetPasswordScreen extends StatefulWidget {
  final Future<String?> Function(String newPassword)? onResetPassword;
  final VoidCallback? onDone;

  const ResetPasswordScreen({
    super.key,
    this.onResetPassword,
    this.onDone,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? errorMessage;
    if (widget.onResetPassword != null) {
      errorMessage = await widget.onResetPassword!(_passwordController.text);
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
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // var authButton = AuthButton;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Center(child: GlowBadge(icon: Icons.password_rounded)),
                const SizedBox(height: 28),
                Text('Set a new password',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Choose a strong password you haven\'t used before',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _passwordController,
                  label: 'New password',
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _confirmController,
                  label: 'Confirm new password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 28),
               AuthButton(
  label: 'Reset Password',
  isLoading: _isLoading,
  onPressed: _handleReset,
),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}