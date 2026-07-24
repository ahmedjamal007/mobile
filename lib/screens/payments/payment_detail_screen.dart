import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/payment.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/receipt_image.dart';
import '../../widgets/status_badge.dart';

class PaymentDetailScreen extends StatelessWidget {
  final String paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: AsyncView<Payment>(
        loader: () => Services.I.payments.detail(paymentId),
        builder: (context, p) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  StatusBadge(label: p.status.label, color: p.status.color),
                  const Spacer(),
                  Text(
                    'Submitted ${Formatters.relative(p.createdAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'RESERVATION',
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.train_outlined,
                      label: 'Train',
                      value: p.trainName.isEmpty ? '—' : p.trainName,
                    ),
                    InfoRow(
                      icon: Icons.route_outlined,
                      label: 'Route',
                      value: '${p.departureStation} → ${p.arrivalStation}',
                    ),
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Departure',
                      value: Formatters.dateTime(p.departureTime),
                    ),
                    const Divider(),
                    InfoRow(
                      label: 'Amount',
                      value: Formatters.money(p.totalPrice),
                      trailing: Text(
                        Formatters.money(p.totalPrice),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'RECEIPT',
                child: ReceiptImage(source: p.receiptUrl, height: 300),
              ),
              if (p.isRejected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_gmailerrorred,
                              color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Payment rejected',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.adminNote?.isNotEmpty == true
                            ? p.adminNote!
                            : 'Please upload a clearer / valid receipt.',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/pay/${p.reservationId}'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resubmit receipt'),
                ),
              ] else if (p.status == PaymentStatus.pending) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top,
                          color: AppColors.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Your receipt is awaiting staff review. You will be '
                            'notified once it is checked.'),
                      ),
                    ],
                  ),
                ),
              ] else if (p.status == PaymentStatus.approved) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/home'),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('View your ticket'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
