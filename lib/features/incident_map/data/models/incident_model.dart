import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';

class IncidentModel extends Incident {
  const IncidentModel({
    required int id,
    int? municipalityId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String status,
    required DateTime createdAt,
  }) : super(
          id: id,
      municipalityId: municipalityId,
          title: title,
          description: description,
          latitude: latitude,
          longitude: longitude,
          status: status,
          createdAt: createdAt,
        );

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final incidentType = json['incident_type'] as Map<String, dynamic>?;
    final incidentTypeName = incidentType?['name'] as String?;

    final rawLatitude = json['latitude'];
    final rawLongitude = json['longitude'];

    final latitude = rawLatitude is num
        ? rawLatitude.toDouble()
        : double.tryParse(rawLatitude?.toString() ?? '') ?? 0.0;
    final longitude = rawLongitude is num
        ? rawLongitude.toDouble()
        : double.tryParse(rawLongitude?.toString() ?? '') ?? 0.0;

    return IncidentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      municipalityId: (json['municipality_id'] as num?)?.toInt(),
      title: incidentTypeName ?? 'Incidencia',
      description: json['description'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipality_id': municipalityId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
