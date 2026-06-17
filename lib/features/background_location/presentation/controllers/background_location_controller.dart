import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/models/background_location_model.dart';
import 'package:seguridad_ciudadana_app/features/background_location/domain/entities/background_location_entity.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class BackgroundLocationState {
  final bool isRunning;
  final BackgroundLocationEntity? lastLocation;
  final String? error;

  BackgroundLocationState({this.isRunning = false, this.lastLocation, this.error});

  BackgroundLocationState copyWith({bool? isRunning, BackgroundLocationEntity? lastLocation, String? error}) {
    return BackgroundLocationState(
      isRunning: isRunning ?? this.isRunning,
      lastLocation: lastLocation ?? this.lastLocation,
      error: error,
    );
  }
}

class BackgroundLocationController extends StateNotifier<BackgroundLocationState> {
  final Ref ref;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  BackgroundLocationController(this.ref) : super(BackgroundLocationState()) {
    _eventSubscription = ref
        .read(backgroundLocationServiceProvider)
        .onLocationChanged
        .listen((event) {
      try {
        final model = BackgroundLocationModel.fromJson(event);
        state = state.copyWith(
          lastLocation: model.toEntity(),
          error: null,
        );
      } catch (error) {
        state = state.copyWith(error: error.toString());
      }
    }, onError: (error) {
      state = state.copyWith(error: error.toString());
    });
  }

  Future<void> start() async {
    state = state.copyWith(isRunning: true, error: null);
    final result = await ref.read(startBackgroundLocationUseCaseProvider).execute();

    result.fold(
      (failure) => state = state.copyWith(isRunning: false, error: failure.message),
      (_) => state = state.copyWith(isRunning: true, error: null),
    );
  }

  Future<void> stop() async {
    final result = await ref.read(stopBackgroundLocationUseCaseProvider).execute();

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => state = state.copyWith(isRunning: false, error: null),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

final backgroundLocationControllerProvider = StateNotifierProvider<BackgroundLocationController, BackgroundLocationState>((ref) {
  return BackgroundLocationController(ref);
});
