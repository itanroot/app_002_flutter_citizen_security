import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/features/sos/domain/entities/sos_entity.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class SosState {
  final bool isSending;
  final String? message;
  final bool isSuccess;

  SosState({this.isSending = false, this.message, this.isSuccess = false});

  SosState copyWith({bool? isSending, String? message, bool? isSuccess}) {
    return SosState(
      isSending: isSending ?? this.isSending,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SosController extends StateNotifier<SosState> {
  final Ref ref;

  SosController(this.ref) : super(SosState());

  Future<void> sendSOS() async {
    state = state.copyWith(isSending: true, message: null, isSuccess: false);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ServerException('El servicio de ubicación está desactivado.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw ServerException('Permiso de ubicación denegado.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw ServerException('Permiso de ubicación denegado permanentemente. Configura los permisos en el sistema.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 20));

      final sosEntity = SosEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        description: 'SOS enviado desde aplicativo',
      );

      final resultFuture = ref.read(sendSosUseCaseProvider).execute(sosEntity);
      final result = await resultFuture.timeout(const Duration(seconds: 30));
      result.fold(
        (failure) {
          state = state.copyWith(isSending: false, message: 'No se pudo enviar el SOS. Intenta nuevamente más tarde.', isSuccess: false);
        },
        (_) {
          state = state.copyWith(isSending: false, message: 'Tu SOS fue enviado correctamente. Un serenzago será notificado y atenderá tu caso lo antes posible.', isSuccess: true);
        },
      );
    } on ServerException catch (e) {
      state = state.copyWith(isSending: false, message: e.message, isSuccess: false);
    } catch (e) {
      if (e is TimeoutException) {
        state = state.copyWith(isSending: false, message: 'No se pudo enviar el SOS. Revisa tu conexión e inténtalo nuevamente.', isSuccess: false);
      } else {
        state = state.copyWith(isSending: false, message: 'No se pudo enviar el SOS. Intenta nuevamente más tarde.', isSuccess: false);
      }
    }
  }
}

final sosControllerProvider = StateNotifierProvider<SosController, SosState>((ref) {
  return SosController(ref);
});
