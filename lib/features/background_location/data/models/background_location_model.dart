import 'package:seguridad_ciudadana_app/features/background_location/domain/entities/background_location_entity.dart';

class BackgroundLocationModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const BackgroundLocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory BackgroundLocationModel.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final timestampMs = (json['timestamp'] as num?)?.toInt();

    if (latitude == null || longitude == null || timestampMs == null) {
      throw FormatException('Invalid background location payload');
    }

    return BackgroundLocationModel(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  BackgroundLocationEntity toEntity() {
    return BackgroundLocationEntity(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );
  }
}
