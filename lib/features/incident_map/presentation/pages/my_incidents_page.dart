import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/controllers/incident_map_controller.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class MyIncidentsPage extends ConsumerStatefulWidget {
  const MyIncidentsPage({super.key});

  @override
  ConsumerState<MyIncidentsPage> createState() => _MyIncidentsPageState();
}

class _MyIncidentsPageState extends ConsumerState<MyIncidentsPage> {
  GoogleMapController? _mapController;
  bool _isDisposed = false;

  bool get _canUseRef => mounted && !_isDisposed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canUseRef) return;
      _loadMyIncidents();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyIncidents() async {
    if (!_canUseRef) {
      return;
    }

    final controller = IncidentMapController(
      ref,
      ref.read(getIncidentsUseCaseProvider),
      ref.read(getPendingIncidentsUseCaseProvider),
      getMy: ref.read(getMyIncidentsUseCaseProvider),
      canUpdate: () => _canUseRef,
    );

    await controller.loadMy();

    if (!_canUseRef) {
      return;
    }

    await _focusOnFirstIncident();
  }

  Future<void> _focusOnFirstIncident() async {
    if (!_canUseRef) {
      return;
    }

    final incidents = ref.read(incidentListProvider);
    if (_mapController == null || incidents.isEmpty) {
      return;
    }

    final first = incidents.first;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(first.latitude, first.longitude),
          zoom: 14,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$m-$d $h:$min';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('assigned') || normalized.contains('progress')) {
      return Colors.orange.shade700;
    }
    if (normalized.contains('closed') || normalized.contains('resolved') || normalized.contains('finished')) {
      return Colors.green.shade700;
    }
    return Colors.blueGrey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentListProvider);
    final loading = ref.watch(incidentLoadingProvider);

    final markers = incidents.map(
      (i) => Marker(
        markerId: MarkerId(i.id.toString()),
        position: LatLng(i.latitude, i.longitude),
        infoWindow: InfoWindow(
          title: i.title,
          snippet: '${i.incidentStateName} · ${i.incidentTypeName}',
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mis incidencias')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
                  onMapCreated: (c) async {
                    _mapController = c;
                    await _focusOnFirstIncident();
                  },
                  markers: Set<Marker>.of(markers),
                ),
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (!loading && incidents.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Text('No tienes incidencias registradas aún.'),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return _IncidentTile(
                  incident: incident,
                  statusColor: _statusColor(incident.incidentStateName),
                  formattedCreatedAt: _formatDate(incident.createdAt),
                  formattedClosedAt: incident.closedAt != null ? _formatDate(incident.closedAt!) : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadMyIncidents,
        label: const Text('Actualizar'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final Incident incident;
  final Color statusColor;
  final String formattedCreatedAt;
  final String? formattedClosedAt;

  const _IncidentTile({
    required this.incident,
    required this.statusColor,
    required this.formattedCreatedAt,
    this.formattedClosedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Icon(Icons.location_pin, color: statusColor),
        title: Text(incident.title),
        subtitle: Text(
          '${incident.incidentStateName} · ${incident.incidentTypeName}\n'
          '${incident.description}\n'
          'Municipio: ${incident.municipalityName}\n'
          'Creado: $formattedCreatedAt'
          '${formattedClosedAt != null ? '\nCerrado: $formattedClosedAt' : ''}'
          '${incident.assignedSerenazgoName != null ? '\nAsignado a: ${incident.assignedSerenazgoName}' : ''}'
          '${incident.assignmentStatus != null ? '\nEstado asignación: ${incident.assignmentStatus}' : ''}',
        ),
        isThreeLine: true,
        trailing: Text(
          '#${incident.id}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
