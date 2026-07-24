import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../models/reservation.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/receipt_image.dart';

/// Upload a payment receipt for a PENDING_PAYMENT reservation. Also the
/// resubmit flow after a rejection — it's the same screen shown again.
class PaymentUploadScreen extends StatefulWidget {
  final String reservationId;
  const PaymentUploadScreen({super.key, required this.reservationId});

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  String? _receiptPath;
  bool _submitting = false;

  Future<void> _pick() async {
    final path = await ImageHelper.pick(context);
    if (path != null) setState(() => _receiptPath = path);
  }

  Future<void> _submit() async {
    if (_receiptPath == null) {
      Toast.error(context, 'Please attach a receipt image first.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await Services.I.payments.create(widget.reservationId, _receiptPath!);
      if (!mounted) return;
      Toast.success(context, 'Receipt submitted. It is now under review.');
      // Nothing more to do here, and popping would land back on the
      // reservation mid-flow. `go` clears the reserve → pay stack so the
      // receipt screen can't be reached again with the back button.
      context.go('/home');
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload receipt')),
      body: AsyncView<Reservation>(
        loader: () => Services.I.reservations.detail(widget.reservationId),
        enableRefresh: false,
        builder: (context, r) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'PAYING FOR',
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.train_outlined,
                      label: 'Train',
                      value: r.trainName.isEmpty ? '—' : r.trainName,
                    ),
                    InfoRow(
                      icon: Icons.route_outlined,
                      label: 'Route',
                      value: '${r.departureStation} → ${r.arrivalStation}',
                    ),
                    InfoRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seats',
                      value: '${r.seats}',
                    ),
                    const Divider(),
                    InfoRow(
                      label: 'Amount to pay',
                      value: Formatters.money(r.totalPrice),
                      trailing: Text(
                        Formatters.money(r.totalPrice),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transfer the amount using your preferred method, then attach a '
                'clear photo of the receipt below. Staff will review and confirm '
                'your booking.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_receiptPath != null) ...[
                ReceiptImage(source: _receiptPath, height: 260),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _pick,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Replace'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _receiptPath = null),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ] else
                _UploadDropzone(onTap: _pick),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting || _receiptPath == null ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Submit receipt'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadDropzone({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryLight,
            style: BorderStyle.solid,
            width: 1.4,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 40, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Attach receipt',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            SizedBox(height: 4),
            Text('Camera or gallery',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
