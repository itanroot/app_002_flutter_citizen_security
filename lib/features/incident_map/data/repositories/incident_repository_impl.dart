import 'package:seguridad_ciudadana_app/features/incident_map/data/datasources/incident_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/models/incident_model.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource remote;

  IncidentRepositoryImpl(this.remote);

  @override
  Future<List<Incident>> getAllIncidents() async {
    final models = await remote.fetchAllIncidents();
    return models;
  }

  @override
  Future<List<Incident>> getPendingIncidents() async {
    final models = await remote.fetchPendingIncidents();
    return models;
  }
}
