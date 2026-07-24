/// A railway station. Keys match `stations.serializers.StationSerializer`.
///
/// [city] has no backend column; it stays null against the real API and is
/// only populated by the mock.
class Station {
  final String id;
  final String name;
  final String? city;
  final String? code;
  final bool isActive;

  const Station({
    required this.id,
    required this.name,
    this.city,
    this.code,
    this.isActive = true,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Station',
      city: json['city']?.toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] != false,
    );
  }
}
