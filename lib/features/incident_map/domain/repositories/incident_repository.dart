import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';

abstract class IncidentRepository {
  Future<List<Incident>> getAllIncidents();
  Future<List<Incident>> getPendingIncidents();
}
