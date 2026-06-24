import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:seguridad_ciudadana_app/core/constants/incident_taxonomy.dart';
import 'package:seguridad_ciudadana_app/core/services/serenazgo_location_realtime_service.dart';
import 'package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/controllers/incident_map_controller.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class MyIncidentsOsmPage extends ConsumerStatefulWidget {
  const MyIncidentsOsmPage({super.key});

  @override
  ConsumerState<MyIncidentsOsmPage> createState() => _MyIncidentsOsmPageState();
}

class _MyIncidentsOsmPageState extends ConsumerState<MyIncidentsOsmPage> {
  final MapController _mapController = MapController();
  late final SerenazgoLocationRealtimeService _realtimeService;
  bool _isDisposed = false;
  bool _mapReady = false;
  bool _realtimeConnected = false;
  int? _selectedIncidentId;
  String? _selectedMarkerTitle;
  String? _selectedMarkerSnippet;
  final Map<int, GlobalKey> _incidentTileKeys = {};
  // Posiciones vivas de serenazgo keyed by serenazgo_id (actualizadas por WS).
  final Map<int, LatLng> _liveSerenazgoPositions = {};

  bool get _canUseRef => mounted && !_isDisposed;

  void _showGenericError() {
    if (!_canUseRef) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Ocurrio un error. Intentalo de nuevo mas tarde.'),
      ),
    );
  }

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
    String? markerTitle,
    String? markerSnippet,
  }) async {
    if (!_canUseRef) return;

    setState(() {
      _selectedIncidentId = incident.id;
      _selectedMarkerTitle = markerTitle ?? '#${incident.id} - ${incident.title}';
      _selectedMarkerSnippet = markerSnippet ??
          '${incident.incidentStateDescription} · ${incident.incidentTypeName}';
    });

    await _scrollToIncident(incident.id);

    if (_mapReady) {
      final position = target ?? LatLng(incident.latitude, incident.longitude);
      _mapController.move(position, 15);
    }
  }

  @override
  void initState() {
    super.initState();
    _realtimeService = ref.read(serenazgoLocationRealtimeServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canUseRef) return;
      unawaited(_loadMyIncidents());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_realtimeService.disconnect());
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMyIncidents() async {
    if (!_canUseRef) {
      return;
    }

    try {
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
      await _connectRealtime();
    } catch (_) {
      _showGenericError();
    }
  }

  Future<void> _connectRealtime() async {
    if (!_canUseRef || _realtimeConnected) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.user == null) {
      return;
    }

    final incidents = ref.read(incidentListProvider);
    final municipalityId = incidents.isNotEmpty
        ? incidents.first.municipalityId
        : null;

    if (municipalityId == null) {
      return;
    }

    final connectionResult = await _realtimeService.connectToMunicipality(
      municipalityId: municipalityId,
      onLocationUpdated: ({
        required int serenazgoId,
        required double latitude,
        required double longitude,
      }) {
        if (!_canUseRef) return;

        setState(() {
          _liveSerenazgoPositions[serenazgoId] = LatLng(latitude, longitude);
        });
      },
    );

    if (!_canUseRef) {
      return;
    }

    _realtimeConnected =
        connectionResult == SerenazgoLocationConnectionResult.connected &&
        _realtimeService.isConnected;

    if (connectionResult == SerenazgoLocationConnectionResult.failed) {
      _showGenericError();
    }
  }

  Future<void> _focusOnFirstIncident() async {
    if (!_canUseRef) {
      return;
    }

    final incidents = ref.read(incidentListProvider);
    if (!_mapReady || incidents.isEmpty) {
      return;
    }

    final first = incidents.first;
    _mapController.move(
      LatLng(first.latitude, first.longitude),
      14,
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

  void _goBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }

    context.go('/home');
  }

  List<Marker> _buildMarkers(List<Incident> incidents) {
    final markers = <Marker>[];

    for (final incident in incidents) {
      final isSelected = _selectedIncidentId == incident.id;

      markers.add(
        Marker(
          point: LatLng(incident.latitude, incident.longitude),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              unawaited(_selectIncident(incident));
            },
            child: Icon(
              Icons.location_pin,
              size: 48,
              color: isSelected ? Colors.lightBlueAccent : Colors.red,
            ),
          ),
        ),
      );

      if (incident.incidentStateId == IncidentStateIds.inRoute &&
          (incident.serenazgoLatitude != null ||
              (incident.assignedSerenazgoProfileId != null &&
                  _liveSerenazgoPositions.containsKey(
                    incident.assignedSerenazgoProfileId,
                  )) ||
              (incident.assignedSerenazgoId != null &&
                  _liveSerenazgoPositions.containsKey(incident.assignedSerenazgoId)))) {
        // Prefiere la posición en vivo del WS si está disponible.
        final liveSerenazgoKey =
            incident.assignedSerenazgoProfileId ?? incident.assignedSerenazgoId;
        final livePos = liveSerenazgoKey != null
            ? _liveSerenazgoPositions[liveSerenazgoKey]
            : null;
        final serenazgoPoint = livePos ??
            (incident.serenazgoLatitude != null
                ? LatLng(
                    incident.serenazgoLatitude!,
                    incident.serenazgoLongitude!,
                  )
                : null);

        if (serenazgoPoint != null) {
          markers.add(
            Marker(
              point: serenazgoPoint,
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () {
                  unawaited(
                    _selectIncident(
                      incident,
                      target: serenazgoPoint,
                      markerTitle:
                          incident.assignedSerenazgoName ?? 'Serenazgo asignado',
                      markerSnippet:
                          'En ruta hacia la incidencia #${incident.id}',
                    ),
                  );
                },
                child: Icon(
                  Icons.directions_car,
                  size: 48,
                  color: isSelected ? Colors.yellowAccent : Colors.orange,
                ),
              ),
            ),
          );
        }
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
        leading: IconButton(
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
        title: const Text('Mis incidencias'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(0, 0),
                    initialZoom: 2,
                    onTap: (tapPosition, point) {
                      if (_selectedMarkerTitle == null &&
                          _selectedMarkerSnippet == null) {
                        return;
                      }

                      setState(() {
                        _selectedMarkerTitle = null;
                        _selectedMarkerSnippet = null;
                      });
                    },
                    onMapReady: () {
                      _mapReady = true;
                      unawaited(_focusOnFirstIncident());
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'seguridad_ciudadana_app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                if (_selectedMarkerTitle != null)
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedMarkerTitle!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((_selectedMarkerSnippet ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _selectedMarkerSnippet!,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
                    unawaited(_selectIncident(incident));
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _realtimeConnected = false;
          await _realtimeService.disconnect();
          await _loadMyIncidents();
        },
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