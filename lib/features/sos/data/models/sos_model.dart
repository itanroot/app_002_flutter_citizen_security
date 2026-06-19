import '../../domain/entities/sos_entity.dart';

class SosModel {
  final double latitude;
  final double longitude;
  final String description;
  final String deviceUuid;

  SosModel({
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.deviceUuid,
  });

  factory SosModel.fromEntity(SosEntity entity, {required String deviceUuid}) {
    return SosModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      description: entity.description,
      deviceUuid: deviceUuid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'device_uuid': deviceUuid,
    };
  }
}
