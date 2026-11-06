import 'package:demo_app/core/theme/app_colors.dart';
import 'package:demo_app/core/theme/glow.dart';
import 'package:flutter/material.dart';

class AuthOptionsScreen extends StatefulWidget {
  final Future<void> Function() onGoogle;
  final VoidCallback onEmail;

  const AuthOptionsScreen({
    super.key,
    required this.onGoogle,
    required this.onEmail,
  });

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  bool _googleLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await widget.onGoogle();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in could not start. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: GlowBadge(icon: Icons.auto_awesome_rounded)),
              const SizedBox(height: 28),
              Text(
                'Get started',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to continue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 36),
              _OptionButton(
                icon: Icons.g_mobiledata_rounded,
                label: _googleLoading
                    ? 'Connecting to Google…'
                    : 'Continue with Google',
                onTap: _continueWithGoogle,
                isLoading: _googleLoading,
              ),
              const SizedBox(height: 14),
              _OptionButton(
                icon: Icons.mail_outline_rounded,
                label: 'Continue with Email',
                onTap: _googleLoading ? null : widget.onEmail,
                filled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool isLoading;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: filled ? null : AppColors.fieldFill,
        border: filled ? null : Border.all(color: AppColors.fieldBorder),
        gradient: filled
            ? const LinearGradient(
                colors: [AppColors.primaryDeep, AppColors.primary],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              else
                Icon(icon, color: AppColors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
