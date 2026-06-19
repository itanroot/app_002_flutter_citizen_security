import 'package:seguridad_ciudadana_app/features/incident_map/data/models/incident_model.dart';

abstract class IncidentRemoteDataSource {
  Future<List<IncidentModel>> fetchAllIncidents();
  Future<List<IncidentModel>> fetchPendingIncidents();
  Future<List<IncidentModel>> fetchMyIncidents({String? deviceUuid});
}
