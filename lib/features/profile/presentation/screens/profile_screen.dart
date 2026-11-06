import 'package:demo_app/app/app_routes.dart';
import 'package:demo_app/features/profile/presentation/widgets/logout_dialog.dart';
import 'package:demo_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:demo_app/features/profile/presentation/widgets/profile_option.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : 'EmoSense User';
          final providers =
              user?.providerData
                  .map((provider) => _providerName(provider.providerId))
                  .toSet()
                  .join(', ') ??
              'Not available';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Center(child: ProfileAvatar()),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _accountCard(user, providers),
              const SizedBox(height: 8),
              _sectionTitle('Account'),
              ProfileOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
              ),
              ProfileOptionTile(
                icon: Icons.info_outline_rounded,
                title: 'About EmoSense',
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              ),
              const SizedBox(height: 8),
              ProfileOptionTile(
                icon: Icons.logout_rounded,
                title: 'Logout or Delete Account',
                onTap: () => showLogoutDialog(context),
                logout: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _accountCard(User? user, String providers) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff1E293B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _detail(Icons.email_outlined, 'Email', user?.email ?? 'Not provided'),
        const SizedBox(height: 12),
        _detail(
          user?.emailVerified == true
              ? Icons.verified_outlined
              : Icons.mark_email_unread_outlined,
          'Email status',
          user?.email == null
              ? 'Not available'
              : user!.emailVerified
              ? 'Verified'
              : 'Not verified',
        ),
        const SizedBox(height: 12),
        _detail(Icons.login_rounded, 'Sign-in method', providers),
        if (user?.metadata.creationTime != null) ...[
          const SizedBox(height: 12),
          _detail(
            Icons.calendar_month_outlined,
            'Member since',
            _formatDate(user!.metadata.creationTime!),
          ),
        ],
      ],
    ),
  );

  Widget _detail(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xff60A5FA), size: 19),
      const SizedBox(width: 11),
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  String _providerName(String id) => switch (id) {
    'password' => 'Email and password',
    'google.com' => 'Google',
    'apple.com' => 'Apple',
    _ => 'Linked account',
  };

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
