import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/entities/location_entity.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/start_location_tracking_usecase.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/stop_location_tracking_usecase.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/watch_location_updates_usecase.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';
import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';

class LocationState {
  final bool isTracking;
  final LocationEntity? currentLocation;
  final String? error;

  LocationState({this.isTracking = false, this.currentLocation, this.error});

  LocationState copyWith({bool? isTracking, LocationEntity? currentLocation, String? error}) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      currentLocation: currentLocation ?? this.currentLocation,
      error: error,
    );
  }
}

class LocationController extends StateNotifier<LocationState> {
  final Ref ref;
  StreamSubscription<Either<Failure, LocationEntity>>? _locationSubscription;

  LocationController(this.ref) : super(LocationState());

  Future<void> startTracking() async {
    state = state.copyWith(isTracking: true, error: null);
    final result = await ref.read(startLocationTrackingUseCaseProvider).execute();

    result.fold(
      (failure) {
        state = state.copyWith(isTracking: false, error: failure.message);
      },
      (_) {
        _subscribeToLocationUpdates();
      },
    );
  }

  Future<void> stopTracking() async {
    final result = await ref.read(stopLocationTrackingUseCaseProvider).execute();
    await _cancelSubscription();

    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (_) {
        state = state.copyWith(isTracking: false);
      },
    );
  }

  void _subscribeToLocationUpdates() {
    if (_locationSubscription != null) {
      return;
    }

    _locationSubscription = ref
        .read(watchLocationUpdatesUseCaseProvider)
        .execute()
        .listen((result) {
      result.fold(
        (failure) {
          state = state.copyWith(error: failure.message);
        },
        (location) {
          state = state.copyWith(currentLocation: location, error: null);
        },
      );
    });
  }

  Future<void> _cancelSubscription() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}

final locationControllerProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(ref);
});
