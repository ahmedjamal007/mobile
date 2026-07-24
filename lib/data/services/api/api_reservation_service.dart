import '../../../core/constants/api_constants.dart';
import '../../../models/reservation.dart';
import '../../api_client.dart';
import '../reservation_service.dart';
import 'api_parsing.dart';

/// Reservations are always scoped server-side to the authenticated user, so
/// there is no user id to pass anywhere here.
class ApiReservationService implements ReservationService {
  final ApiClient _client;

  ApiReservationService(this._client);

  @override
  Future<Reservation> create(String scheduleId, int seats) async {
    final res = await _client.post(
      ApiConstants.reservationCreate,
      data: {'schedule': scheduleId, 'seats': seats},
    );
    return Reservation.fromJson(asMap(res.data));
  }

  @override
  Future<List<Reservation>> myReservations() async {
    final res = await _client.get(ApiConstants.reservations);
    return asList(res.data).map(Reservation.fromJson).toList();
  }

  @override
  Future<Reservation> detail(String id) async {
    final res = await _client.get(ApiConstants.reservationDetail(id));
    return Reservation.fromJson(asMap(res.data));
  }
}
