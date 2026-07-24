import 'package:flutter/material.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/payment.dart';
import '../../widgets/receipt_image.dart';

/// Result returned from [ReviewSheet].
class ReviewResult {
  final PaymentStatus decision;
  final String note;
  const ReviewResult(this.decision, this.note);
}

/// Bottom sheet for approving/rejecting a payment with an optional admin note.
/// Maps to `PATCH /api/payments/<uuid>/review/`.
class ReviewSheet extends StatefulWidget {
  final Payment payment;
  const ReviewSheet({super.key, required this.payment});

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _note = TextEditingController();
  bool _rejecting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit(PaymentStatus decision) {
    // Encourage a reason when rejecting.
    if (decision == PaymentStatus.rejected && _note.text.trim().isEmpty) {
      setState(() => _rejecting = true);
      return;
    }
    Navigator.pop(context, ReviewResult(decision, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.passengerName ?? 'Passenger',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  Formatters.money(p.totalPrice),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${p.trainName} · ${p.departureStation} → ${p.arrivalStation}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ReceiptImage(source: p.receiptUrl, height: 280, fit: BoxFit.contain),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              maxLines: 3,
              onChanged: (_) {
                if (_rejecting) setState(() => _rejecting = false);
              },
              decoration: InputDecoration(
                labelText: 'Note to passenger (optional for approval)',
                hintText: 'e.g. Receipt is unclear, please resend.',
                alignLabelWithHint: true,
                errorText: _rejecting
                    ? 'Please add a reason so the passenger can fix it.'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _submit(PaymentStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submit(PaymentStatus.approved),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
