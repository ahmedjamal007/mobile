import '../core/constants/api_constants.dart';
import '../core/enums/app_enums.dart';

/// A receipt-upload payment awaiting / having gone through staff review.
class Payment {
  final String id;
  final String reservationId;
  final String? receiptUrl;
  final PaymentStatus status;
  final String? adminNote;
  final DateTime? createdAt;

  // Snapshot for the staff queue (`reservation_info` on each payment).
  final String trainName;
  final String departureStation;
  final String arrivalStation;
  final DateTime? departureTime;
  final double totalPrice;
  final int seats;
  final String? passengerName;

  const Payment({
    required this.id,
    required this.reservationId,
    this.receiptUrl,
    required this.status,
    this.adminNote,
    this.createdAt,
    this.trainName = '',
    this.departureStation = '',
    this.arrivalStation = '',
    this.departureTime,
    this.totalPrice = 0,
    this.seats = 0,
    this.passengerName,
  });

  bool get isRejected => status == PaymentStatus.rejected;

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  /// Keys match `payments.serializers.PaymentSerializer`, whose
  /// `reservation_info` block carries the trip snapshot the staff queue shows.
  factory Payment.fromJson(Map<String, dynamic> json) {
    final info = json['reservation_info'] is Map<String, dynamic>
        ? json['reservation_info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return Payment(
      id: json['id']?.toString() ?? '',
      reservationId:
          json['reservation']?.toString() ?? info['id']?.toString() ?? '',
      receiptUrl: ApiConstants.mediaUrl(json['receipt']?.toString()),
      status: PaymentStatusX.fromApi(json['status']?.toString()),
      adminNote: json['admin_note']?.toString(),
      createdAt: _d(json['created_at']),
      trainName: info['train']?.toString() ?? '',
      departureStation: info['departure_station']?.toString() ?? '',
      arrivalStation: info['arrival_station']?.toString() ?? '',
      departureTime: _d(info['departure_datetime']),
      totalPrice: (info['total_price'] is num)
          ? (info['total_price'] as num).toDouble()
          : double.tryParse(info['total_price']?.toString() ?? '') ?? 0,
      seats: (info['seats'] is num) ? (info['seats'] as num).toInt() : 0,
      passengerName: info['passenger_name']?.toString(),
    );
  }
}
