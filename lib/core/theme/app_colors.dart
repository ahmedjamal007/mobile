import 'package:flutter/material.dart';

/// Central palette for the Sudan Railways app.
///
/// The brand leans on a deep railway green with a warm amber accent
/// (evocative of Sudan's flag and desert routes). Status colors are shared
/// across reservation / payment / ticket badges so the whole app reads
/// consistently.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E5A43); // deep railway green
  static const Color primaryDark = Color(0xFF0A4331);
  static const Color primaryLight = Color(0xFF3B8B70);
  static const Color accent = Color(0xFFE0A106); // amber

  // Surfaces
  static const Color background = Color(0xFFF5F7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF2F0);

  // Text
  static const Color textPrimary = Color(0xFF15201C);
  static const Color textSecondary = Color(0xFF5C6B65);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Feedback
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A106);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3A7BD5);

  // Borders / dividers
  static const Color border = Color(0xFFDCE4E1);
}
