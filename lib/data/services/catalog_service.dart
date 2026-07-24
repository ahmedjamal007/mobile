import '../../models/schedule.dart';
import '../../models/station.dart';
import '../../models/train.dart';
import '../mock/mock_backend.dart';

/// Schedules / stations / trains browsing.
///
/// [trains] and [createSchedule] back the admin-only "add schedule" screen;
/// the create endpoint is enforced as admin-only server-side.
abstract class CatalogService {
  Future<List<Schedule>> schedules();
  Future<List<Station>> stations();
  Future<List<Train>> trains();
  Future<Schedule> createSchedule({
    required String trainId,
    required String departureStationId,
    required String arrivalStationId,
    required DateTime departure,
    required DateTime arrival,
    required double ticketPrice,
    required int availableSeats,
  });
  Future<Train> createTrain({
    required String trainNumber,
    required String name,
    required int capacity,
    required String trainType,
  });
  Future<Station> createStation({
    required String name,
    required String code,
  });
}

class MockCatalogService implements CatalogService {
  final _backend = MockBackend.instance;

  @override
  Future<List<Schedule>> schedules() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_backend.schedules);
  }

  @override
  Future<List<Station>> stations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_backend.stations);
  }

  @override
  Future<List<Train>> trains() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_backend.trains);
  }

  @override
  Future<Schedule> createSchedule({
    required String trainId,
    required String departureStationId,
    required String arrivalStationId,
    required DateTime departure,
    required DateTime arrival,
    required double ticketPrice,
    required int availableSeats,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _backend.createSchedule(
      trainId: trainId,
      departureStationId: departureStationId,
      arrivalStationId: arrivalStationId,
      departure: departure,
      arrival: arrival,
      ticketPrice: ticketPrice,
      availableSeats: availableSeats,
    );
  }

  @override
  Future<Train> createTrain({
    required String trainNumber,
    required String name,
    required int capacity,
    required String trainType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _backend.createTrain(
      trainNumber: trainNumber,
      name: name,
      capacity: capacity,
      trainType: trainType,
    );
  }

  @override
  Future<Station> createStation({
    required String name,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _backend.createStation(name: name, code: code);
  }
}
