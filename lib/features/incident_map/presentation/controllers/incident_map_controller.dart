import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/usecases/get_incidents_usecase.dart';

enum IncidentMapFilter { all, pending }

final incidentListProvider = StateProvider<List<Incident>>((ref) => []);
final incidentLoadingProvider = StateProvider<bool>((ref) => false);
final incidentMapFilterProvider = StateProvider<IncidentMapFilter>((ref) => IncidentMapFilter.all);

class IncidentMapController {
  final WidgetRef ref;
  final GetIncidentsUseCase getAll;
  final GetPendingIncidentsUseCase getPending;

  IncidentMapController(this.ref, this.getAll, this.getPending);

  Future<void> loadAll() async {
    ref.read(incidentLoadingProvider.notifier).state = true;
    try {
      final list = await getAll();
      ref.read(incidentListProvider.notifier).state = list;
    } finally {
      ref.read(incidentLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadPending() async {
    ref.read(incidentLoadingProvider.notifier).state = true;
    try {
      final list = await getPending();
      ref.read(incidentListProvider.notifier).state = list;
    } finally {
      ref.read(incidentLoadingProvider.notifier).state = false;
    }
  }
}
