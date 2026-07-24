import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/reservation.dart';
import '../../widgets/async_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/trip_route.dart';

/// "My Reservations" (Trips tab). Auto-filtered to the current user by the
/// backend.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Reservation>>(
      loader: () => Services.I.reservations.myReservations(),
      builder: (context, list) {
        if (list.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const EmptyView(
                  icon: Icons.event_seat_outlined,
                  title: 'No trips yet',
                  subtitle:
                      'Reserve a seat from the Home tab and it will show up here.',
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
          itemBuilder: (context, i) => _ReservationCard(reservation: list[i]),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/reservation/${reservation.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reservation.trainName.isEmpty
                          ? 'Reservation'
                          : reservation.trainName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusBadge(
                    label: reservation.status.label,
                    color: reservation.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TripRoute(
                fromStation: reservation.departureStation,
                toStation: reservation.arrivalStation,
                departure: reservation.departureTime,
                arrival: reservation.arrivalTime,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_seat_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${reservation.seats} seat(s)',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(
                    Formatters.money(reservation.totalPrice),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ],
              ),
              if (reservation.status.canPay) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/pay/${reservation.id}'),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload payment receipt'),
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
