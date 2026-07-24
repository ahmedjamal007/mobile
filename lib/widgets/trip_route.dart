import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Departure → arrival visual with station names and times, used on schedule
/// cards, reservation/payment/ticket details.
class TripRoute extends StatelessWidget {
  final String fromStation;
  final String toStation;
  final DateTime? departure;
  final DateTime? arrival;
  final String? durationLabel;

  const TripRoute({
    super.key,
    required this.fromStation,
    required this.toStation,
    this.departure,
    this.arrival,
    this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _endpoint(fromStation, departure, CrossAxisAlignment.start),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
                    const Expanded(
                      child: DottedLine(),
                    ),
                    const Icon(Icons.train_rounded,
                        size: 18, color: AppColors.primary),
                    const Expanded(child: DottedLine()),
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.accent),
                  ],
                ),
                if (durationLabel != null && durationLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      durationLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _endpoint(toStation, arrival, CrossAxisAlignment.end),
      ],
    );
  }

  Widget _endpoint(String station, DateTime? time, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          Formatters.time(time),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 84,
          child: Text(
            station,
            textAlign:
                align == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A simple horizontal dotted separator.
class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 3.0;
        const dashSpace = 3.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count > 0 ? count : 1,
            (_) => Container(
              width: dashWidth,
              height: 1.4,
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}
