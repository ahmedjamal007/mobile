import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_helpers.dart';

/// Support contact for password resets.
///
/// There is no reset endpoint — passwords are reset by staff on request, so
/// the app points the user at WhatsApp rather than a dead form.
const String supportWhatsAppNumber = '+249 96 556 6667';

/// Digits only, for copying and for a future `wa.me` deep link.
const String supportWhatsAppDigits = '249965566667';

Future<void> showForgotPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ForgotPasswordDialog(),
  );
}

class _ForgotPasswordDialog extends StatelessWidget {
  const _ForgotPasswordDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_reset, color: AppColors.primary, size: 32),
      title: const Text('Forgot your password?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Contact Sudan Railways support on WhatsApp and our team will '
            'help you reset it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Tap to copy: the number is the whole point of this dialog, and a
          // long number is easy to mistype.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: supportWhatsAppNumber),
              );
              if (context.mounted) {
                Toast.success(context, 'Number copied.');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  const Text(
                    supportWhatsAppNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.copy,
                      size: 15,
                      color: AppColors.textSecondary.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the number to copy it.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
