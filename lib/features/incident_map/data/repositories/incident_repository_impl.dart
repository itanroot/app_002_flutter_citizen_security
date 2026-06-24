import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seguridad_ciudadana_app/core/security/device_uuid_service.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/datasources/incident_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/models/incident_model.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;
  final DeviceUuidService deviceUuidService;

  IncidentRepositoryImpl(this.remote, this.secureStorage, this.deviceUuidService);

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

  @override
  Future<List<Incident>> getMyIncidents() async {
    final token = await secureStorage.read(key: 'auth_token');
    final shouldUseDeviceUuid = token == null || token.isEmpty;
    final deviceUuid = shouldUseDeviceUuid ? await deviceUuidService.getOrCreate() : null;
    final List<IncidentModel> models = await remote.fetchMyIncidents(deviceUuid: deviceUuid);
    return models;
  }

  @override
  Future<void> attendSosIncident({required int incidentId, required int userId}) {
    return remote.attendSosIncident(incidentId: incidentId, userId: userId);
  }
}
