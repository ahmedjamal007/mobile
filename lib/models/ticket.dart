/// An issued ticket. Created automatically by the backend when staff
/// approves the linked payment.
class Ticket {
  final String id;
  final String ticketNumber;
  final String passengerName;
  final String trainName;
  final String departureStation;
  final String arrivalStation;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int seats;
  final double totalPrice;
  final String status;

  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.passengerName,
    required this.trainName,
    required this.departureStation,
    required this.arrivalStation,
    this.departureTime,
    this.arrivalTime,
    required this.seats,
    required this.totalPrice,
    this.status = 'VALID',
  });

  /// Backend statuses are ACTIVE / USED / CANCELLED; only ACTIVE is usable.
  bool get isValid => status.toUpperCase() == 'ACTIVE';

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  /// Keys match `tickets.serializers.TicketSerializer`. `passenger` comes from
  /// `get_full_name`, which is empty when the user has no first/last name, so
  /// fall back to the username the serializer also sends.
  factory Ticket.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger']?.toString() ?? '';
    return Ticket(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      passengerName: passenger.isNotEmpty
          ? passenger
          : json['username']?.toString() ?? '',
      trainName: json['train']?.toString() ?? '',
      departureStation: json['departure_station']?.toString() ?? '',
      arrivalStation: json['arrival_station']?.toString() ?? '',
      departureTime: _d(json['departure_datetime']),
      arrivalTime: _d(json['arrival_datetime']),
      seats: (json['seats'] is num) ? (json['seats'] as num).toInt() : 0,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toDouble()
          : double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}
