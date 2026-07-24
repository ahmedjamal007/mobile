/// A physical train. Keys match `trains.serializers.TrainSerializer`.
class Train {
  final String id;
  final String trainNumber;
  final String name;
  final int? capacity;

  /// PASSENGER / EXPRESS / FREIGHT.
  final String trainType;

  /// ACTIVE / INACTIVE.
  final String status;

  const Train({
    required this.id,
    required this.name,
    this.trainNumber = '',
    this.capacity,
    this.trainType = 'PASSENGER',
    this.status = 'ACTIVE',
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  /// "T-100 · Nile Express", falling back to the name alone.
  String get label => trainNumber.isEmpty ? name : '$trainNumber · $name';

  factory Train.fromJson(Map<String, dynamic> json) {
    return Train(
      id: json['id']?.toString() ?? '',
      trainNumber: json['train_number']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Train',
      capacity:
          json['capacity'] is num ? (json['capacity'] as num).toInt() : null,
      trainType: json['train_type']?.toString() ?? 'PASSENGER',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}
