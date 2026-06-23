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
  final String? incidentTypeColorBackground;
  final String incidentStateName;
  final String incidentStateDescription;
  final String? incidentStateColorBackground;
  final String? incidentStateColorText;
  final String municipalityName;
  final String? assignmentStatus;
  final String? assignedSerenazgoName;
  final double? serenazgoLatitude;
  final double? serenazgoLongitude;
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
    this.incidentTypeColorBackground,
    required this.incidentStateName,
    required this.incidentStateDescription,
    this.incidentStateColorBackground,
    this.incidentStateColorText,
    required this.municipalityName,
    this.assignmentStatus,
    this.assignedSerenazgoName,
    this.serenazgoLatitude,
    this.serenazgoLongitude,
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
        incidentTypeColorBackground,
        incidentStateName,
        incidentStateDescription,
        incidentStateColorBackground,
        incidentStateColorText,
        municipalityName,
        assignmentStatus,
        assignedSerenazgoName,
        serenazgoLatitude,
        serenazgoLongitude,
        createdAt,
        closedAt,
      ];
}
