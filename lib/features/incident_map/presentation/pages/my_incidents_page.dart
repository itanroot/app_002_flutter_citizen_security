import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:seguridad_ciudadana_app/core/constants/incident_taxonomy.dart';
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
  int? _selectedIncidentId;
  final Map<int, GlobalKey> _incidentTileKeys = {};

  bool get _canUseRef => mounted && !_isDisposed;

  GlobalKey _incidentTileKey(int incidentId) {
    return _incidentTileKeys.putIfAbsent(incidentId, () => GlobalKey());
  }

  Future<void> _scrollToIncident(int incidentId) async {
    if (!_canUseRef) return;

    final key = _incidentTileKeys[incidentId];
    final context = key?.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.25,
    );
  }

  Future<void> _selectIncident(
    Incident incident, {
    LatLng? target,
  }) async {
    if (!_canUseRef) return;

    setState(() {
      _selectedIncidentId = incident.id;
    });

    await _scrollToIncident(incident.id);

    final mapController = _mapController;
    if (mapController != null) {
      final position = target ?? LatLng(incident.latitude, incident.longitude);
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }

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

  Color _statusColor(Incident incident) {
    final stateId = incident.incidentStateId;
    if (stateId == IncidentStateIds.accepted ||
        stateId == IncidentStateIds.inRoute ||
        stateId == IncidentStateIds.arrived) {
      return Colors.orange.shade700;
    }
    if (stateId == IncidentStateIds.resolved ||
        stateId == IncidentStateIds.closed) {
      return Colors.green.shade700;
    }
    return Colors.blueGrey.shade700;
  }

  void _openOsmVersion(BuildContext context) {
    context.go('/my-incidents-osm');
  }

  Set<Marker> _buildMarkers(List<Incident> incidents) {
    final markers = <Marker>{};

    for (final incident in incidents) {
      final isSelected = _selectedIncidentId == incident.id;

      markers.add(
        Marker(
          markerId: MarkerId('incident_${incident.id}'),
          position: LatLng(incident.latitude, incident.longitude),
          zIndex: isSelected ? 2 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            _selectIncident(incident);
          },
          infoWindow: InfoWindow(
            title: '#${incident.id} - ${incident.title}',
            snippet: '${incident.incidentStateDescription} · ${incident.incidentTypeName}',
          ),
        ),
      );

      if (incident.incidentStateId == IncidentStateIds.inRoute &&
          incident.serenazgoLatitude != null &&
          incident.serenazgoLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('serenazgo_${incident.id}'),
            position: LatLng(
              incident.serenazgoLatitude!,
              incident.serenazgoLongitude!,
            ),
            zIndex: isSelected ? 2 : 1,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueOrange,
            ),
            onTap: () {
              _selectIncident(
                incident,
                target: LatLng(
                  incident.serenazgoLatitude!,
                  incident.serenazgoLongitude!,
                ),
              );
            },
            infoWindow: InfoWindow(
              title: incident.assignedSerenazgoName ?? 'Serenazgo asignado',
              snippet: 'En ruta hacia la incidencia #${incident.id}',
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentListProvider);
    final loading = ref.watch(incidentLoadingProvider);

    final markers = _buildMarkers(incidents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis incidencias'),
        actions: [
          TextButton.icon(
            onPressed: () => _openOsmVersion(context),
            icon: const Icon(Icons.public, size: 18),
            label: const Text('OSM'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 2,
                  ),
                  onMapCreated: (c) async {
                    _mapController = c;
                    await _focusOnFirstIncident();
                  },
                  markers: markers,
                ),
                if (loading) const Center(child: CircularProgressIndicator()),
                if (!loading && incidents.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'No tienes incidencias registradas aún.',
                      ),
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
                  key: _incidentTileKey(incident.id),
                  incident: incident,
                  statusColor: _statusColor(incident),
                  formattedCreatedAt: _formatDate(incident.createdAt),
                  formattedClosedAt: incident.closedAt != null
                      ? _formatDate(incident.closedAt!)
                      : null,
                  selected: _selectedIncidentId == incident.id,
                  onTap: () {
                    _selectIncident(incident);
                  },
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
  final bool selected;
  final VoidCallback onTap;

  const _IncidentTile({
    super.key,
    required this.incident,
    required this.statusColor,
    required this.formattedCreatedAt,
    required this.selected,
    required this.onTap,
    this.formattedClosedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 1.3,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: selected ? 4 : 1,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Icon(
            selected ? Icons.place : Icons.location_pin,
            color: selected ? theme.colorScheme.primary : statusColor,
          ),
          title: Text(incident.title),
          subtitle: Text(
            '${incident.incidentStateDescription} · ${incident.incidentTypeName}\n'
            '${incident.description}\n'
            'Jurisdicción: ${incident.municipalityName}\n'
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
      ),
    );
  }
}
