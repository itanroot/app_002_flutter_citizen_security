import 'package:equatable/equatable.dart';

class Incident extends Equatable {
  final int id;
  final int? municipalityId;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String status; // e.g. pending, resolved, in_progress
  final DateTime createdAt;

  const Incident({
    required this.id,
    this.municipalityId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, municipalityId, title, description, latitude, longitude, status, createdAt];
}
