import 'package:flutter/material.dart';

import '../../../core/enums/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/schedule.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/trip_route.dart';

/// Tappable schedule summary card used on the Home list.
class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const ScheduleCard({super.key, required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lowSeats = schedule.seatsAvailable > 0 && schedule.seatsAvailable <= 5;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.train_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.trainName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // A departed trip still reports AVAILABLE from the backend,
                  // so show that it has gone rather than inviting a booking
                  // the API will refuse.
                  StatusBadge(
                    label: schedule.hasDeparted
                        ? 'Departed'
                        : schedule.status.label,
                    color: schedule.hasDeparted
                        ? AppColors.textSecondary
                        : schedule.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                Formatters.date(schedule.departureTime),
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TripRoute(
                fromStation: schedule.departureStation,
                toStation: schedule.arrivalStation,
                departure: schedule.departureTime,
                arrival: schedule.arrivalTime,
                durationLabel: schedule.durationLabel,
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat_outlined,
                        size: 16,
                        color: lowSeats ? AppColors.error : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.seatsAvailable > 0
                            ? '${schedule.seatsAvailable} seats'
                            : 'Sold out',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: lowSeats
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight:
                              lowSeats ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    Formatters.money(schedule.ticketPrice),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    ' /seat',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
