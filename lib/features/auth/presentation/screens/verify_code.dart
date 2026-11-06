import 'dart:async';
import 'package:demo_app/core/theme/app_colors.dart';
import 'package:demo_app/core/theme/glow.dart';
import 'package:demo_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:demo_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:flutter/material.dart';


class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final Future<String?> Function(String code)? onVerify;
  final Future<void> Function()? onResendCode;
  final VoidCallback? onBack;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    this.onVerify,
    this.onResendCode,
    this.onBack,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  String _code = '';
  bool _isLoading = false;
  bool _canResend = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 6-digit code'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? errorMessage;
    if (widget.onVerify != null) {
      errorMessage = await widget.onVerify!(_code);
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
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    await widget.onResendCode?.call();
    if (!mounted) return;
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code resent'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: GlowBadge(icon: Icons.mark_email_read_outlined)),
                      const SizedBox(height: 28),
                      Text('Check your email',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleMedium,
                          children: [
                            const TextSpan(text: "We sent a 6-digit code to "),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      OtpInput(onChanged: (value) => _code = value),
                      const SizedBox(height: 28),
                      AuthButton(
                        label: 'Verify',
                        isLoading: _isLoading,
                        onPressed: _handleVerify,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: _canResend
                            ? TextButton(
                                onPressed: _handleResend,
                                child: const Text('Resend code'),
                              )
                            : Text(
                                'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                      ),
                    ],
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