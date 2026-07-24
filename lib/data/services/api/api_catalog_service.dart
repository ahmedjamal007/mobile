import '../../../core/constants/api_constants.dart';
import '../../../models/schedule.dart';
import '../../../models/station.dart';
import '../../../models/train.dart';
import '../../api_client.dart';
import '../catalog_service.dart';
import 'api_parsing.dart';

/// Schedules, stations and trains. The list endpoints are readable by any
/// logged-in user; [createSchedule] is admin-only and rejected with 403
/// otherwise.
class ApiCatalogService implements CatalogService {
  final ApiClient _client;

  ApiCatalogService(this._client);

  @override
  Future<List<Schedule>> schedules() async {
    final res = await _client.get(ApiConstants.schedules);
    return asList(res.data).map(Schedule.fromJson).toList();
  }

  @override
  Future<List<Station>> stations() async {
    final res = await _client.get(ApiConstants.stations);
    return asList(res.data).map(Station.fromJson).toList();
  }

  @override
  Future<List<Train>> trains() async {
    final res = await _client.get(ApiConstants.trains);
    return asList(res.data).map(Train.fromJson).toList();
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
    final res = await _client.post(
      ApiConstants.scheduleCreate,
      data: {
        'train': trainId,
        'departure_station': departureStationId,
        'arrival_station': arrivalStationId,
        // The API stores UTC; send an absolute instant rather than a local
        // wall-clock string so the server doesn't reinterpret the zone.
        'departure_datetime': departure.toUtc().toIso8601String(),
        'arrival_datetime': arrival.toUtc().toIso8601String(),
        'ticket_price': ticketPrice.toStringAsFixed(2),
        'available_seats': availableSeats,
      },
    );
    return Schedule.fromJson(asMap(res.data));
  }

  @override
  Future<Train> createTrain({
    required String trainNumber,
    required String name,
    required int capacity,
    required String trainType,
  }) async {
    // Trains are created on the same path the list uses; only POST is
    // admin-gated.
    final res = await _client.post(
      ApiConstants.trains,
      data: {
        'train_number': trainNumber,
        'name': name,
        'capacity': capacity,
        'train_type': trainType,
      },
    );
    return Train.fromJson(asMap(res.data));
  }

  @override
  Future<Station> createStation({
    required String name,
    required String code,
  }) async {
    final res = await _client.post(
      ApiConstants.stationCreate,
      data: {'name': name, 'code': code, 'is_active': true},
    );
    return Station.fromJson(asMap(res.data));
  }
}
