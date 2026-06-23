import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/repositories/incident_repository.dart';

class GetIncidentsUseCase {
  final IncidentRepository repository;

  GetIncidentsUseCase(this.repository);

  Future<List<Incident>> call() async {
    return repository.getAllIncidents();
  }
}

class GetPendingIncidentsUseCase {
  final IncidentRepository repository;

  GetPendingIncidentsUseCase(this.repository);

  Future<List<Incident>> call() async {
    return repository.getPendingIncidents();
  }
}

class GetMyIncidentsUseCase {
  final IncidentRepository repository;

  GetMyIncidentsUseCase(this.repository);

  Future<List<Incident>> call() async {
    return repository.getMyIncidents();
  }
}

class AttendSosIncidentUseCase {
  final IncidentRepository repository;

  AttendSosIncidentUseCase(this.repository);

  Future<void> call({required int incidentId, required int userId}) {
    return repository.attendSosIncident(incidentId: incidentId, userId: userId);
  }
}
