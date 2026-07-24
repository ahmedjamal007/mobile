import '../core/enums/app_enums.dart';

/// A train run between two stations at a given time, with a price and
/// remaining seat count. The list endpoint returns these with related
/// train/station info already joined (`select_related`).
class Schedule {
  final String id;
  final String trainName;
  final String departureStation;
  final String arrivalStation;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double ticketPrice;
  final int seatsAvailable;
  final ScheduleStatus status;

  /// Server-computed. `status` alone is not enough: nothing flips a schedule
  /// to COMPLETED once it departs, so a past trip still reports AVAILABLE.
  final bool hasDeparted;

  const Schedule({
    required this.id,
    required this.trainName,
    required this.departureStation,
    required this.arrivalStation,
    this.departureTime,
    this.arrivalTime,
    required this.ticketPrice,
    required this.seatsAvailable,
    this.status = ScheduleStatus.available,
    this.hasDeparted = false,
  });

  /// The single check the UI should use before offering to book.
  bool get canBook =>
      status.isBookable && !hasDeparted && seatsAvailable > 0;

  Duration? get duration => (departureTime != null && arrivalTime != null)
      ? arrivalTime!.difference(departureTime!)
      : null;

  String get durationLabel {
    final d = duration;
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  /// Keys match `schedules.serializers.ScheduleSerializer`.
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id']?.toString() ?? '',
      trainName: json['train_name']?.toString() ?? 'Train',
      departureStation: json['departure_station_name']?.toString() ?? '—',
      arrivalStation: json['arrival_station_name']?.toString() ?? '—',
      departureTime: _parseDate(json['departure_datetime']),
      arrivalTime: _parseDate(json['arrival_datetime']),
      ticketPrice: (json['ticket_price'] is num)
          ? (json['ticket_price'] as num).toDouble()
          : double.tryParse(json['ticket_price']?.toString() ?? '') ?? 0,
      seatsAvailable: (json['available_seats'] is num)
          ? (json['available_seats'] as num).toInt()
          : int.tryParse(json['available_seats']?.toString() ?? '') ?? 0,
      status: ScheduleStatusX.fromApi(json['status']?.toString()),
      // Fall back to a local comparison for older payloads that predate the
      // server-computed flag.
      hasDeparted: json['has_departed'] is bool
          ? json['has_departed'] as bool
          : _parseDate(json['departure_datetime'])
                  ?.isBefore(DateTime.now()) ??
              false,
    );
  }
}
