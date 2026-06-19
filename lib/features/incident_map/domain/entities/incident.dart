import 'package:equatable/equatable.dart';

class Incident extends Equatable {
  final int id;
  final int? municipalityId;
  final int? incidentTypeId;
  final int? incidentStateId;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String status;
  final String incidentTypeName;
  final String incidentStateName;
  final String municipalityName;
  final String? assignmentStatus;
  final String? assignedSerenazgoName;
  final DateTime createdAt;
  final DateTime? closedAt;

  const Incident({
    required this.id,
    this.municipalityId,
    this.incidentTypeId,
    this.incidentStateId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.incidentTypeName,
    required this.incidentStateName,
    required this.municipalityName,
    this.assignmentStatus,
    this.assignedSerenazgoName,
    required this.createdAt,
    this.closedAt,
  });

  @override
  List<Object?> get props => [
        id,
        municipalityId,
        incidentTypeId,
        incidentStateId,
        title,
        description,
        latitude,
        longitude,
        status,
        incidentTypeName,
        incidentStateName,
        municipalityName,
        assignmentStatus,
        assignedSerenazgoName,
        createdAt,
        closedAt,
      ];
}
