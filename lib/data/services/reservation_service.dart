import '../../models/reservation.dart';
import '../api_exception.dart';
import '../mock/mock_backend.dart';

abstract class ReservationService {
  Future<Reservation> create(String scheduleId, int seats);
  Future<List<Reservation>> myReservations();
  Future<Reservation> detail(String id);
}

class MockReservationService implements ReservationService {
  final _backend = MockBackend.instance;

  @override
  Future<Reservation> create(String scheduleId, int seats) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _backend.createReservation(scheduleId, seats);
  }

  @override
  Future<List<Reservation>> myReservations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_backend.reservations);
  }

  @override
  Future<Reservation> detail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _backend.reservations.firstWhere(
      (r) => r.id == id,
      orElse: () =>
          throw const ApiException('Reservation not found.', statusCode: 404),
    );
  }
}
