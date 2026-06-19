import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';

class IncidentModel extends Incident {
  const IncidentModel({
    required int id,
    int? municipalityId,
    int? incidentTypeId,
    int? incidentStateId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String status,
    required String incidentTypeName,
    required String incidentStateName,
    required String municipalityName,
    String? assignmentStatus,
    String? assignedSerenazgoName,
    required DateTime createdAt,
    DateTime? closedAt,
  }) : super(
          id: id,
          municipalityId: municipalityId,
          incidentTypeId: incidentTypeId,
          incidentStateId: incidentStateId,
          title: title,
          description: description,
          latitude: latitude,
          longitude: longitude,
          status: status,
          incidentTypeName: incidentTypeName,
          incidentStateName: incidentStateName,
          municipalityName: municipalityName,
          assignmentStatus: assignmentStatus,
          assignedSerenazgoName: assignedSerenazgoName,
          createdAt: createdAt,
          closedAt: closedAt,
        );

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final incidentType = json['incident_type'] as Map<String, dynamic>?;
    final incidentState = json['incident_state'] as Map<String, dynamic>?;
    final municipality = json['municipality'] as Map<String, dynamic>?;
    final assignments = json['assignments'] as List<dynamic>?;
    final firstAssignment = assignments != null && assignments.isNotEmpty
        ? assignments.first as Map<String, dynamic>?
        : null;
    final serenazgo = firstAssignment?['serenazgo'] as Map<String, dynamic>?;

    final incidentTypeName = incidentType?['name'] as String?;
    final incidentStateName = incidentState?['name'] as String?;
    final municipalityName = municipality?['name'] as String?;

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
      incidentTypeId: (json['incident_type_id'] as num?)?.toInt(),
      incidentStateId: (json['incident_state_id'] as num?)?.toInt(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : (incidentTypeName ?? 'Incidencia'),
      description: json['description'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      status: (json['status'] as String?) ?? (incidentStateName ?? 'open'),
      incidentTypeName: incidentTypeName ?? 'Desconocido',
      incidentStateName: incidentStateName ?? 'open',
      municipalityName: municipalityName ?? 'Sin municipio',
      assignmentStatus: firstAssignment?['status'] as String?,
      assignedSerenazgoName: serenazgo?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      closedAt: json['closed_at'] != null ? DateTime.tryParse(json['closed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipality_id': municipalityId,
      'incident_type_id': incidentTypeId,
      'incident_state_id': incidentStateId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'incident_type_name': incidentTypeName,
      'incident_state_name': incidentStateName,
      'municipality_name': municipalityName,
      'assignment_status': assignmentStatus,
      'assigned_serenazgo_name': assignedSerenazgoName,
      'created_at': createdAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }
}
