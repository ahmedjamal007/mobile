import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/service_locator.dart';
import '../../models/ticket.dart';
import '../../widgets/async_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/trip_route.dart';

/// "My Tickets" tab. Tickets are issued automatically once staff approves the
/// linked payment — no client action creates them.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Ticket>>(
      loader: () => Services.I.tickets.myTickets(),
      builder: (context, list) {
        if (list.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const EmptyView(
                  icon: Icons.confirmation_number_outlined,
                  title: 'No tickets yet',
                  subtitle:
                      'Once your payment is approved, your ticket appears here '
                      'automatically.',
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
          itemBuilder: (context, i) => _TicketCard(ticket: list[i]),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/ticket/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.ticketNumber,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ),
                  StatusBadge(
                    label: ticket.isValid ? 'Valid' : ticket.status,
                    color:
                        ticket.isValid ? AppColors.success : AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(ticket.trainName,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TripRoute(
                fromStation: ticket.departureStation,
                toStation: ticket.arrivalStation,
                departure: ticket.departureTime,
                arrival: ticket.arrivalTime,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${ticket.seats} seat(s)',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(Formatters.date(ticket.departureTime),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
