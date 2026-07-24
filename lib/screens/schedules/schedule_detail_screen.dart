import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../core/utils/formatters.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../models/schedule.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/trip_route.dart';

/// Schedule detail. The passenger-facing retrieve endpoint is admin-only on
/// the backend today, so we resolve the schedule from the cached list — the
/// same data the Home tab already loaded. Swap to a real detail fetch once the
/// backend exposes one.
class ScheduleDetailScreen extends StatelessWidget {
  final String scheduleId;
  const ScheduleDetailScreen({super.key, required this.scheduleId});

  Future<Schedule> _load() async {
    final all = await Services.I.catalog.schedules();
    return all.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () =>
          throw const ApiException('Schedule not found.', statusCode: 404),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: AsyncView<Schedule>(
        loader: _load,
        enableRefresh: false,
        builder: (context, s) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.trainName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusBadge(
                            label: s.status.label, color: s.status.color),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TripRoute(
                      fromStation: s.departureStation,
                      toStation: s.arrivalStation,
                      departure: s.departureTime,
                      arrival: s.arrivalTime,
                      durationLabel: s.durationLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'DETAILS',
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Departure',
                      value: Formatters.dateTime(s.departureTime),
                    ),
                    InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Arrival',
                      value: Formatters.dateTime(s.arrivalTime),
                    ),
                    InfoRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seats available',
                      value: '${s.seatsAvailable}',
                    ),
                    InfoRow(
                      icon: Icons.sell_outlined,
                      label: 'Price per seat',
                      value: Formatters.money(s.ticketPrice),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Schedule>(
            future: _load(),
            builder: (context, snap) {
              final s = snap.data;
              final bookable = s != null && s.canBook;
              return ElevatedButton.icon(
                onPressed: bookable
                    ? () => context.push('/reserve/$scheduleId')
                    : null,
                icon: const Icon(Icons.event_seat),
                label: Text(
                  s == null
                      ? 'Reserve seats'
                      : bookable
                          ? 'Reserve seats'
                          // Say which reason applies, so a disabled button is
                          // never a mystery.
                          : s.hasDeparted
                              ? 'Already departed'
                              : s.seatsAvailable == 0
                                  ? 'Sold out'
                                  : 'Not available',
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
