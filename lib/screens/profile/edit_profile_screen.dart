import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../state/auth_provider.dart';
import '../../widgets/info_row.dart';

/// Edit phone / gender and upload profile + national ID photos
/// (`PUT /api/auth/profile/update/`, multipart for the file fields).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late String _gender;
  String? _profilePhotoPath;
  String? _nationalIdPhotoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
    _gender = (user?.gender == 'F') ? 'F' : 'M';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickProfile() async {
    final path = await ImageHelper.pick(context);
    if (path != null) setState(() => _profilePhotoPath = path);
  }

  Future<void> _pickNationalId() async {
    final path = await ImageHelper.pick(context);
    if (path != null) setState(() => _nationalIdPhotoPath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await Services.I.auth.updateProfile(
        {
          'phone_number': _phone.text.trim(),
          'gender': _gender,
        },
        profilePhotoPath: _profilePhotoPath,
        nationalIdPhotoPath: _nationalIdPhotoPath,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      Toast.success(context, 'Profile updated.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _AvatarPicker(
                    localPath: _profilePhotoPath,
                    remoteUrl: user?.profilePhotoUrl,
                    fallback: user?.initials ?? '?',
                    onTap: _pickProfile,
                  ),
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'CONTACT',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Phone number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? 'M'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'NATIONAL ID PHOTO',
                  child: _DocumentPicker(
                    localPath: _nationalIdPhotoPath,
                    remoteUrl: user?.nationalIdPhotoUrl,
                    onTap: _pickNationalId,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Photos are compressed on your device before upload. Your '
                  'verification badge is set by staff after review.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? localPath;
  final String? remoteUrl;
  final String fallback;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.localPath,
    required this.remoteUrl,
    required this.fallback,
    required this.onTap,
  });

  ImageProvider? _image() {
    if (localPath != null && File(localPath!).existsSync()) {
      return FileImage(File(localPath!));
    }
    if (remoteUrl != null && remoteUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(remoteUrl!);
    }
    if (remoteUrl != null && File(remoteUrl!).existsSync()) {
      return FileImage(File(remoteUrl!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image();
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: image,
            child: image == null
                ? Text(fallback,
                    style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w700))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  final String? localPath;
  final String? remoteUrl;
  final VoidCallback onTap;

  const _DocumentPicker({
    required this.localPath,
    required this.remoteUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (localPath != null && File(localPath!).existsSync()) ||
        (remoteUrl != null && remoteUrl!.isNotEmpty);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasImage ? Icons.check_circle_outline : Icons.badge_outlined,
              size: 32,
              color: hasImage ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              hasImage ? 'ID photo attached — tap to change' : 'Attach ID photo',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
