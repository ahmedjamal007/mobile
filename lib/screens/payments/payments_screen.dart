import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/payment.dart';
import '../../widgets/async_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

/// "My Payments" list. Reachable from a reservation or the profile menu.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My payments')),
      body: AsyncView<List<Payment>>(
        loader: () => Services.I.payments.myPayments(),
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No payments yet',
              subtitle:
                  'When you upload a receipt for a reservation it will appear here.',
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PaymentCard(payment: list[i]),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/payment/${payment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.trainName.isEmpty
                          ? 'Payment'
                          : '${payment.departureStation} → ${payment.arrivalStation}',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusBadge(
                    label: payment.status.label,
                    color: payment.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Submitted ${Formatters.relative(payment.createdAt)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(Formatters.money(payment.totalPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              if (payment.isRejected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.adminNote?.isNotEmpty == true
                              ? payment.adminNote!
                              : 'Rejected. Please resubmit a valid receipt.',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/pay/${payment.reservationId}'),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Resubmit receipt'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
