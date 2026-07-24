import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks an image from camera or gallery and compresses it client-side before
/// it's handed to the upload layer (per the file-upload requirements).
class ImageHelper {
  ImageHelper._();

  static final _picker = ImagePicker();

  /// Shows a camera/gallery chooser, then returns a compressed file path
  /// (or null if the user cancels).
  static Future<String?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _compress(picked.path);
  }

  static Future<String?> _compress(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/srrs_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        quality: 70,
        minWidth: 1200,
        minHeight: 1200,
      );
      return result?.path ?? path;
    } catch (_) {
      // If compression fails (e.g. unsupported platform), fall back to the
      // original picked file so the flow still works.
      return File(path).existsSync() ? path : null;
    }
  }
}
