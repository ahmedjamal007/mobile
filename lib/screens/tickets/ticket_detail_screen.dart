import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/ticket.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';

/// A boarding-pass style ticket. Staff verify it by reading the ticket
/// number — there is no code to scan.
class TicketDetailScreen extends StatelessWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: AsyncView<Ticket>(
        loader: () => Services.I.tickets.detail(ticketId),
        enableRefresh: false,
        builder: (context, t) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TicketPass(ticket: t),
              const SizedBox(height: 16),
              SectionCard(
                title: 'PASSENGER & TRIP',
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.person_outline,
                      label: 'Passenger',
                      value: t.passengerName.isEmpty ? '—' : t.passengerName,
                    ),
                    InfoRow(
                      icon: Icons.train_outlined,
                      label: 'Train',
                      value: t.trainName,
                    ),
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Departure',
                      value: Formatters.dateTime(t.departureTime),
                    ),
                    InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Arrival',
                      value: Formatters.dateTime(t.arrivalTime),
                    ),
                    InfoRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seats',
                      value: '${t.seats}',
                    ),
                    const Divider(),
                    InfoRow(
                      label: 'Total paid',
                      value: Formatters.money(t.totalPrice),
                      trailing: Text(
                        Formatters.money(t.totalPrice),
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
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Show this ticket to staff when boarding.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _TicketPass extends StatelessWidget {
  final Ticket ticket;
  const _TicketPass({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.train_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text('Sudan Railways',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.isValid ? 'VALID' : ticket.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _RouteLine(
              from: ticket.departureStation,
              to: ticket.arrivalStation,
              fromTime: Formatters.time(ticket.departureTime),
              toTime: Formatters.time(ticket.arrivalTime),
            ),
            const SizedBox(height: 20),
            // Perforation.
            Row(
              children: List.generate(
                30,
                (_) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // With no QR, the number is what staff read off the pass, so it
            // carries the emphasis the code used to.
            Center(
              child: Column(
                children: [
                  Text(
                    'TICKET NUMBER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.ticketNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String from;
  final String to;
  final String fromTime;
  final String toTime;

  const _RouteLine({
    required this.from,
    required this.to,
    required this.fromTime,
    required this.toTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fromTime,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(from,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(toTime,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(to,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
