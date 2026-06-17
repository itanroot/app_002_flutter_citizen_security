import '../../domain/entities/sos_entity.dart';

class SosModel {
  final double latitude;
  final double longitude;
  final String description;

  SosModel({
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  factory SosModel.fromEntity(SosEntity entity) {
    return SosModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      description: entity.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }
}
