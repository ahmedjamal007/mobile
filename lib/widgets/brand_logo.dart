import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Simple built-in brand mark (train inside a rounded badge) so the app has an
/// identity without shipping image assets.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool light;

  const BrandLogo({super.key, this.size = 72, this.light = false});

  @override
  Widget build(BuildContext context) {
    final bg = light ? Colors.white : AppColors.primary;
    final fg = light ? AppColors.primary : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.train_rounded, color: fg, size: size * 0.56),
    );
  }
}
