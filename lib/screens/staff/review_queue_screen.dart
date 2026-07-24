import 'package:flutter/material.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../models/payment.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/receipt_image.dart';
import '../../widgets/state_views.dart';
import 'review_sheet.dart';

/// Staff / admin payment-review queue (`GET /api/payments/pending/`,
/// oldest first). Reused as a tab inside the shell ([embedded] = true) and as
/// a standalone route.
class ReviewQueueScreen extends StatefulWidget {
  final bool embedded;
  const ReviewQueueScreen({super.key, this.embedded = false});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  final _key = GlobalKey<AsyncViewState<List<Payment>>>();

  Future<void> _review(Payment payment) async {
    final result = await showModalBottomSheet<ReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(payment: payment),
    );
    if (result == null) return;
    try {
      await Services.I.payments
          .review(payment.id, result.decision, result.note);
      if (!mounted) return;
      Toast.success(
        context,
        result.decision == PaymentStatus.approved
            ? 'Payment approved — ticket issued to the passenger.'
            : 'Payment rejected — passenger notified to resubmit.',
      );
      _key.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AsyncView<List<Payment>>(
      key: _key,
      loader: () => Services.I.payments.pending(),
      builder: (context, list) {
        if (list.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const EmptyView(
                  icon: Icons.task_alt,
                  title: 'Queue is clear',
                  subtitle: 'There are no payments waiting for review.',
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _QueueCard(
            payment: list[i],
            index: i + 1,
            onReview: () => _review(list[i]),
          ),
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment review')),
      body: body,
    );
  }
}

class _QueueCard extends StatelessWidget {
  final Payment payment;
  final int index;
  final VoidCallback onReview;

  const _QueueCard({
    required this.payment,
    required this.index,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text('$index',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.passengerName ?? 'Passenger',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        'Waiting ${Formatters.relative(payment.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.money(payment.totalPrice),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InfoRow(
              icon: Icons.train_outlined,
              label: 'Train',
              value: payment.trainName.isEmpty ? '—' : payment.trainName,
            ),
            InfoRow(
              icon: Icons.route_outlined,
              label: 'Route',
              value: '${payment.departureStation} → ${payment.arrivalStation}',
            ),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Departs',
              value: Formatters.dateTime(payment.departureTime),
            ),
            InfoRow(
              icon: Icons.event_seat_outlined,
              label: 'Seats',
              value: '${payment.seats}',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ReceiptImage(source: payment.receiptUrl, height: 180),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Review payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
