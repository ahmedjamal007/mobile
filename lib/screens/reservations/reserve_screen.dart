import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../models/schedule.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';
import '../../widgets/trip_route.dart';

/// Pick a seat count and create a reservation. The total is previewed
/// client-side (`ticket_price * seats`); the backend re-validates on submit.
class ReserveScreen extends StatefulWidget {
  final String scheduleId;
  const ReserveScreen({super.key, required this.scheduleId});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  int _seats = 1;
  bool _submitting = false;

  Future<Schedule> _load() async {
    final all = await Services.I.catalog.schedules();
    return all.firstWhere(
      (s) => s.id == widget.scheduleId,
      orElse: () =>
          throw const ApiException('Schedule not found.', statusCode: 404),
    );
  }

  Future<void> _reserve(Schedule schedule) async {
    setState(() => _submitting = true);
    try {
      final reservation =
          await Services.I.reservations.create(widget.scheduleId, _seats);
      if (!mounted) return;
      Toast.success(context, 'Reserved! Now upload your payment receipt.');
      // Replace so back returns to Home, then land on the reservation.
      context.pushReplacement('/reservation/${reservation.id}');
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserve seats')),
      body: AsyncView<Schedule>(
        loader: _load,
        enableRefresh: false,
        builder: (context, schedule) {
          final maxSeats =
              schedule.seatsAvailable.clamp(1, 10); // sensible per-booking cap
          if (_seats > maxSeats) _seats = maxSeats;
          final total = schedule.ticketPrice * _seats;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.trainName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TripRoute(
                      fromStation: schedule.departureStation,
                      toStation: schedule.arrivalStation,
                      departure: schedule.departureTime,
                      arrival: schedule.arrivalTime,
                      durationLabel: schedule.durationLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'HOW MANY SEATS?',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seats',
                            style: TextStyle(fontSize: 15)),
                        _Stepper(
                          value: _seats,
                          min: 1,
                          max: maxSeats,
                          onChanged: (v) => setState(() => _seats = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${schedule.seatsAvailable} seat(s) available',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'PRICE',
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Price per seat',
                      value: Formatters.money(schedule.ticketPrice),
                    ),
                    InfoRow(label: 'Seats', value: '$_seats'),
                    const Divider(),
                    InfoRow(
                      label: 'Total',
                      value: Formatters.money(total),
                      trailing: Text(
                        Formatters.money(total),
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
              ElevatedButton(
                onPressed: _submitting ? null : () => _reserve(schedule),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text('Reserve · ${Formatters.money(total)}'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reserving holds your seats. Complete payment by uploading a '
                'receipt to confirm the booking.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _btn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon),
      color: onTap == null ? AppColors.border : AppColors.primary,
      onPressed: onTap,
    );
  }
}
