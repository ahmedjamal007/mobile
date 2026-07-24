import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Renders a receipt whether it's a remote URL (staff reviewing an uploaded
/// file) or a local file path (passenger previewing before upload).
class ReceiptImage extends StatelessWidget {
  final String? source;
  final double? height;
  final BoxFit fit;

  const ReceiptImage({
    super.key,
    required this.source,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool get _isRemote =>
      source != null &&
      (source!.startsWith('http://') || source!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (source == null || source!.isEmpty) {
      child = _placeholder(Icons.receipt_long_outlined, 'No receipt');
    } else if (_isRemote) {
      child = CachedNetworkImage(
        imageUrl: source!,
        height: height,
        width: double.infinity,
        fit: fit,
        placeholder: (_, __) => _loading(),
        errorWidget: (_, __, ___) =>
            _placeholder(Icons.broken_image_outlined, 'Could not load receipt'),
      );
    } else {
      final file = File(source!);
      child = file.existsSync()
          ? Image.file(file, height: height, width: double.infinity, fit: fit)
          : _placeholder(Icons.image_outlined, 'Receipt selected');
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }

  Widget _loading() => Container(
        height: height ?? 200,
        color: AppColors.surfaceAlt,
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _placeholder(IconData icon, String label) => Container(
        height: height ?? 200,
        width: double.infinity,
        color: AppColors.surfaceAlt,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}
