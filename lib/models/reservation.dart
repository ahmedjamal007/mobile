import '../core/enums/app_enums.dart';

/// A passenger's seat reservation on a schedule. Total price is
/// `ticket_price * seats`. Carries a snapshot of trip info for display.
class Reservation {
  final String id;
  final String scheduleId;
  final int seats;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime? createdAt;

  // Trip snapshot (joined by the backend for convenience).
  final String trainName;
  final String departureStation;
  final String arrivalStation;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  const Reservation({
    required this.id,
    required this.scheduleId,
    required this.seats,
    required this.totalPrice,
    required this.status,
    this.createdAt,
    this.trainName = '',
    this.departureStation = '',
    this.arrivalStation = '',
    this.departureTime,
    this.arrivalTime,
  });

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  /// Keys match `reservations.serializers.ReservationSerializer`, which
  /// flattens the trip snapshot onto the reservation itself. It carries no
  /// arrival time, so [arrivalTime] stays null here.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id']?.toString() ?? '',
      scheduleId: json['schedule']?.toString() ?? '',
      seats: (json['seats'] is num) ? (json['seats'] as num).toInt() : 0,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toDouble()
          : double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
      status: ReservationStatusX.fromApi(json['status']?.toString()),
      createdAt: _d(json['created_at']),
      trainName: json['train_name']?.toString() ?? '',
      departureStation: json['departure_station']?.toString() ?? '',
      arrivalStation: json['arrival_station']?.toString() ?? '',
      departureTime: _d(json['departure_datetime']),
    );
  }
}
