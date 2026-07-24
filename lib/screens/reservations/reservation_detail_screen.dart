import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/reservation.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/trip_route.dart';

class ReservationDetailScreen extends StatelessWidget {
  final String reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: AsyncView<Reservation>(
        loader: () => Services.I.reservations.detail(reservationId),
        builder: (context, r) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBanner(status: r.status),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.trainName.isEmpty ? 'Trip' : r.trainName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusBadge(
                            label: r.status.label, color: r.status.color),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TripRoute(
                      fromStation: r.departureStation,
                      toStation: r.arrivalStation,
                      departure: r.departureTime,
                      arrival: r.arrivalTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'SUMMARY',
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Departure',
                      value: Formatters.dateTime(r.departureTime),
                    ),
                    InfoRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seats',
                      value: '${r.seats}',
                    ),
                    InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Reference',
                      value: r.id.length > 10
                          ? '#${r.id.substring(r.id.length - 8).toUpperCase()}'
                          : '#${r.id.toUpperCase()}',
                    ),
                    const Divider(),
                    InfoRow(
                      label: 'Total',
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
              const SizedBox(height: 24),
              _actions(context, r),
            ],
          );
        },
      ),
    );
  }

  Widget _actions(BuildContext context, Reservation r) {
    switch (r.status) {
      case ReservationStatus.pendingPayment:
        return ElevatedButton.icon(
          onPressed: () => context.push('/pay/${r.id}'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload payment receipt'),
        );
      case ReservationStatus.paymentSubmitted:
        return OutlinedButton.icon(
          onPressed: () => context.push('/payments'),
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Payment under review — view status'),
        );
      case ReservationStatus.confirmed:
        return ElevatedButton.icon(
          onPressed: () => context.push('/home'),
          icon: const Icon(Icons.confirmation_number_outlined),
          label: const Text('Confirmed — see your ticket in Tickets'),
        );
      case ReservationStatus.cancelled:
      case ReservationStatus.unknown:
        return const SizedBox.shrink();
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final ReservationStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (status) {
      ReservationStatus.pendingPayment => (
          Icons.upload_file,
          'Awaiting payment. Upload your receipt to confirm this reservation.'
        ),
      ReservationStatus.paymentSubmitted => (
          Icons.hourglass_top,
          'Your receipt was submitted and is being reviewed by staff.'
        ),
      ReservationStatus.confirmed => (
          Icons.check_circle_outline,
          'Confirmed! Your ticket has been issued.'
        ),
      ReservationStatus.cancelled => (
          Icons.cancel_outlined,
          'This reservation was cancelled.'
        ),
      ReservationStatus.unknown => (Icons.info_outline, 'Reservation status.'),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: status.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: status.color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
