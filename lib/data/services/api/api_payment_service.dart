import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../models/payment.dart';
import '../../api_client.dart';
import '../payment_service.dart';
import 'api_parsing.dart';

/// Receipt upload (passenger) and the review queue (staff/admin).
///
/// [pending] and [review] are admin-only server-side; the app only reaches
/// them from the Review tab, which is hidden unless the role allows it.
class ApiPaymentService implements PaymentService {
  final ApiClient _client;

  ApiPaymentService(this._client);

  @override
  Future<Payment> create(String reservationId, String receiptPath) async {
    final form = FormData.fromMap({
      'reservation': reservationId,
      'receipt': await MultipartFile.fromFile(receiptPath),
    });

    final res = await _client.post(ApiConstants.paymentCreate, data: form);
    return Payment.fromJson(asMap(res.data));
  }

  @override
  Future<List<Payment>> myPayments() async {
    final res = await _client.get(ApiConstants.payments);
    return asList(res.data).map(Payment.fromJson).toList();
  }

  @override
  Future<Payment> detail(String id) async {
    final res = await _client.get(ApiConstants.paymentDetail(id));
    return Payment.fromJson(asMap(res.data));
  }

  @override
  Future<List<Payment>> pending() async {
    final res = await _client.get(ApiConstants.paymentsPending);
    return asList(res.data).map(Payment.fromJson).toList();
  }

  @override
  Future<Payment> review(
      String id, PaymentStatus decision, String note) async {
    final res = await _client.patch(
      ApiConstants.paymentReview(id),
      data: {
        'status': decision.apiValue,
        // The backend requires a reason on rejection and returns a field error
        // if it's blank, which the review sheet surfaces.
        'admin_note': note,
      },
    );
    return Payment.fromJson(asMap(res.data));
  }
}
