import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../models/user.dart';
import '../../state/auth_provider.dart';
import '../../widgets/info_row.dart';
import '../../widgets/state_views.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoadingView();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(user: user),
        const SizedBox(height: 16),
        SectionCard(
          title: 'ACCOUNT',
          child: Column(
            children: [
              InfoRow(
                icon: Icons.alternate_email,
                label: 'Username',
                value: user.username,
              ),
              InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email.isEmpty ? '—' : user.email,
              ),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phoneNumber?.isNotEmpty == true
                    ? user.phoneNumber!
                    : '—',
              ),
              InfoRow(
                icon: Icons.credit_card_outlined,
                label: 'National ID',
                value:
                    user.nationalId?.isNotEmpty == true ? user.nationalId! : '—',
              ),
              InfoRow(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: switch (user.gender) {
                  'M' => 'Male',
                  'F' => 'Female',
                  _ => '—',
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('My payments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/payments'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) Toast.info(context, 'You have been logged out.');
    }
  }
}

class _Header extends StatelessWidget {
  final User user;
  const _Header({required this.user});

  ImageProvider? _avatar() {
    final url = user.profilePhotoUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return CachedNetworkImageProvider(url);
    final file = File(url);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: _avatar(),
              child: _avatar() == null
                  ? Text(
                      user.initials,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              user.fullName,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _rolePill(user),
                if (user.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolePill(User user) {
    final label = switch (user.role.name) {
      'admin' => 'Admin',
      'staff' => 'Staff',
      _ => 'Passenger',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }
}
