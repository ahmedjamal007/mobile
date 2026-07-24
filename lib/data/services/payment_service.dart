import '../../core/enums/app_enums.dart';
import '../../models/payment.dart';
import '../api_exception.dart';
import '../mock/mock_backend.dart';

abstract class PaymentService {
  /// [receiptPath] is the local file path to upload (multipart in the real API).
  Future<Payment> create(String reservationId, String receiptPath);
  Future<List<Payment>> myPayments();
  Future<Payment> detail(String id);

  // Staff-only.
  Future<List<Payment>> pending();
  Future<Payment> review(String id, PaymentStatus decision, String note);
}

class MockPaymentService implements PaymentService {
  final _backend = MockBackend.instance;

  @override
  Future<Payment> create(String reservationId, String receiptPath) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _backend.createPayment(reservationId, receiptPath);
  }

  @override
  Future<List<Payment>> myPayments() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_backend.payments);
  }

  @override
  Future<Payment> detail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _backend.payments.firstWhere(
      (p) => p.id == id,
      orElse: () =>
          throw const ApiException('Payment not found.', statusCode: 404),
    );
  }

  @override
  Future<List<Payment>> pending() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = _backend.payments
        .where((p) => p.status == PaymentStatus.pending)
        .toList()
      // Oldest first, matching the backend's queue ordering.
      ..sort((a, b) => (a.createdAt ?? DateTime(0))
          .compareTo(b.createdAt ?? DateTime(0)));
    return List.unmodifiable(list);
  }

  @override
  Future<Payment> review(
      String id, PaymentStatus decision, String note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _backend.reviewPayment(id, decision, note);
  }
}
