import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seguridad_ciudadana_app/core/constants/incident_taxonomy.dart';
import 'package:seguridad_ciudadana_app/core/constants/permission_constants.dart';
import 'package:seguridad_ciudadana_app/core/services/incident_realtime_service.dart';
import 'package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/domain/entities/incident.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/controllers/incident_map_controller.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class IncidentMapPage extends ConsumerStatefulWidget {
  const IncidentMapPage({super.key});

  @override
  ConsumerState<IncidentMapPage> createState() => _IncidentMapPageState();
}

class _IncidentMapPageState extends ConsumerState<IncidentMapPage> {
  GoogleMapController? _mapController;
  late final IncidentRealtimeService _realtimeService;
  bool _realtimeConnected = false;
  bool _isDisposed = false;
  final Set<int> _attendingIncidentIds = <int>{};

  bool get _canUseRef => mounted && !_isDisposed;

  Color _hexToColor(String? hex, {required Color fallback}) {
    if (hex == null) return fallback;
    final normalized = hex.trim().replaceAll('#', '');
    if (normalized.length != 6 && normalized.length != 8) {
      return fallback;
    }

    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return fallback;
    }

    if (normalized.length == 6) {
      return Color(0xFF000000 | value);
    }

    return Color(value);
  }

  double _markerHueForIncident(Incident incident) {
    final bgColor = _hexToColor(incident.incidentTypeColorBackground, fallback: Colors.red);
    return HSVColor.fromColor(bgColor).hue;
  }

  bool _hasAttendSosPermission() {
    final user = ref.read(authControllerProvider).user;
    return user?.hasPermission(PermissionConstants.attendIncidentSos) ?? false;
  }

  bool _isSosIncident(Incident incident) {
    return incident.incidentTypeId == IncidentTypeIds.sos ||
        incident.incidentTypeName.trim().toLowerCase() == IncidentTypeNames.sos;
  }

  bool _canAttendIncident(Incident incident) {
    if (!_hasAttendSosPermission() || !_isSosIncident(incident)) {
      return false;
    }

    if (IncidentStateRules.blocksAttendById(incident.incidentStateId)) {
      return false;
    }

    if (IncidentStateRules.blocksAttendByName(incident.status)) {
      return false;
    }

    if (IncidentStateRules.blocksAttendByName(incident.assignmentStatus)) {
      return false;
    }

    return true;
  }

  Future<void> _attendIncident(Incident incident) async {
    if (!_canUseRef || _attendingIncidentIds.contains(incident.id)) {
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      return;
    }

    setState(() {
      _attendingIncidentIds.add(incident.id);
    });

    try {
      await ref.read(attendSosIncidentUseCaseProvider)(incidentId: incident.id, userId: user.id);
      if (!_canUseRef) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La incidencia SOS #${incident.id} fue tomada en atención.')),
      );
      await _loadIncidents();
      await _connectRealtime();
    } catch (e) {
      debugPrint('attendSosIncident unexpected error: $e');
      if (!_canUseRef) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrio un error, intentalo de nuevo mas tarde.')),
      );
    } finally {
      if (_canUseRef) {
        setState(() {
          _attendingIncidentIds.remove(incident.id);
        });
      }
    }
  }

  Future<void> _confirmAttendIncident(Incident incident) async {
    if (!_canAttendIncident(incident) || !_canUseRef) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atender incidencia SOS'),
        content: Text('¿Deseas marcar la incidencia #${incident.id} como en ruta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Atender'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _attendIncident(incident);
    }
  }

  @override
  void initState() {
    super.initState();
    _realtimeService = ref.read(incidentRealtimeServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canUseRef) return;
      _loadIncidents().then((_) => _connectRealtime());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_realtimeService.disconnect());
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    if (!_canUseRef) {
      return;
    }

    final filter = ref.read(incidentMapFilterProvider);
    final controller = IncidentMapController(
      ref,
      ref.read(getIncidentsUseCaseProvider),
      ref.read(getPendingIncidentsUseCaseProvider),
      getMy: ref.read(getMyIncidentsUseCaseProvider),
      canUpdate: () => _canUseRef,
    );

    if (filter == IncidentMapFilter.pending) {
      await controller.loadPending();
    } else {
      await controller.loadAll();
    }

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

  Future<void> _connectRealtime() async {
    if (!_canUseRef || _realtimeConnected) {
      return;
    }

    final user = ref.read(authControllerProvider).user;
    final incidents = ref.read(incidentListProvider);
    final municipalityId = user?.municipalityId ?? (incidents.isNotEmpty ? incidents.first.municipalityId : null);
    if (municipalityId == null) {
      return;
    }

    final connected = await _realtimeService.connectToMunicipality(
      municipalityId: municipalityId,
      onIncidentCreated: () async {
        if (!_canUseRef) return;
        await _loadIncidents();
      },
    );

    if (!_canUseRef) {
      return;
    }

    _realtimeConnected = connected && _realtimeService.isConnected;

    if (!_realtimeConnected && _canUseRef) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrio un error. Intentalo de nuevo mas tarde.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentListProvider);
    final loading = ref.watch(incidentLoadingProvider);
    final filter = ref.watch(incidentMapFilterProvider);
    final canAttendSos = _hasAttendSosPermission();

    final markers = incidents.map((i) {
      final canAttend = _canAttendIncident(i);
      return Marker(
        markerId: MarkerId(i.id.toString()),
        position: LatLng(i.latitude, i.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHueForIncident(i)),
        infoWindow: InfoWindow(
          title: '#${i.id} - ${i.title}',
          snippet: canAttend ? '${i.incidentStateDescription} · Toca aquí para atender SOS' : i.incidentStateDescription,
          onTap: canAttend ? () => _confirmAttendIncident(i) : null,
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Incidents Map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<IncidentMapFilter>(
              segments: const [
                ButtonSegment(value: IncidentMapFilter.all, label: Text('Todas'), icon: Icon(Icons.list_alt)),
                ButtonSegment(value: IncidentMapFilter.pending, label: Text('Pendientes'), icon: Icon(Icons.pending_actions)),
              ],
              selected: {filter},
              onSelectionChanged: (selection) async {
                ref.read(incidentMapFilterProvider.notifier).state = selection.first;
                await _loadIncidents();
                await _connectRealtime();
              },
            ),
          ),
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
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final canAttend = _canAttendIncident(incident);
                final isAttending = _attendingIncidentIds.contains(incident.id);
                final stateBgColor = _hexToColor(
                  incident.incidentStateColorBackground,
                  fallback: Colors.blueGrey.shade100,
                );
                final stateTextColor = _hexToColor(
                  incident.incidentStateColorText,
                  fallback: Colors.black87,
                );
                return Card(
                  child: ListTile(
                    leading: Icon(
                      IncidentStateRules.isPendingById(incident.incidentStateId)
                          ? Icons.pending_actions
                          : Icons.local_shipping_outlined,
                    ),
                    title: Text(incident.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stateBgColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            incident.incidentStateDescription,
                            style: TextStyle(
                              color: stateTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${incident.createdAt.toLocal().toString().substring(0, 16)} - ${incident.description}'),
                      ],
                    ),
                    trailing: SizedBox(
                      width: canAttendSos ? 116 : 64,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canAttend)
                            isAttending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    tooltip: 'Atender SOS',
                                    onPressed: () => _confirmAttendIncident(incident),
                                    icon: const Icon(Icons.local_shipping_outlined),
                                  ),
                          Text(
                            '#${incident.id}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _loadIncidents();
          await _connectRealtime();
        },
        label: const Text('Refresh'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
