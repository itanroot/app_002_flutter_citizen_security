import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/controllers/incident_map_controller.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class IncidentMapPage extends ConsumerStatefulWidget {
  const IncidentMapPage({super.key});

  @override
  ConsumerState<IncidentMapPage> createState() => _IncidentMapPageState();
}

class _IncidentMapPageState extends ConsumerState<IncidentMapPage> {
  GoogleMapController? _mapController;
  bool _realtimeConnected = false;
  bool _isDisposed = false;

  bool get _canUseRef => mounted && !_isDisposed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canUseRef) return;
      _loadIncidents().then((_) => _connectRealtime());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    final realtimeService = ref.read(incidentRealtimeServiceProvider);
    unawaited(realtimeService.disconnect());
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

    await ref.read(incidentRealtimeServiceProvider).connectToMunicipality(
      municipalityId: municipalityId,
      onIncidentCreated: () async {
        if (!_canUseRef) return;
        await _loadIncidents();
      },
    );

    if (!_canUseRef) {
      return;
    }

    _realtimeConnected = true;
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentListProvider);
    final loading = ref.watch(incidentLoadingProvider);
    final filter = ref.watch(incidentMapFilterProvider);

    final markers = incidents.map((i) => Marker(
          markerId: MarkerId(i.id.toString()),
          position: LatLng(i.latitude, i.longitude),
          infoWindow: InfoWindow(title: i.title, snippet: i.status),
        ));

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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      incident.status.toLowerCase().contains('pending') ||
                              incident.status.toLowerCase().contains('open')
                          ? Icons.pending_actions
                          : Icons.assignment_turned_in,
                    ),
                    title: Text(incident.title),
                    subtitle: Text('${incident.status} · ${incident.description}'),
                    trailing: Text(
                      '#${incident.id}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
