import 'package:geolocator/geolocator.dart';
import "package:seguridad_ciudadana_app/core/config/app_config.dart";
import "package:seguridad_ciudadana_app/core/constants/api_constants.dart";
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/datasources/background_location_data_source.dart';
import 'package:seguridad_ciudadana_app/core/services/background_location_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BackgroundLocationDataSourceImpl implements BackgroundLocationDataSource {
  final BackgroundLocationService _service;
  final FlutterSecureStorage _secureStorage;

  BackgroundLocationDataSourceImpl(this._service, this._secureStorage);

  @override
  Future<void> startBackgroundTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ServerException('Los servicios de ubicación están deshabilitados. Habilítelos para continuar.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw ServerException('Permiso de ubicación denegado. Debes permitir el acceso a la ubicación.');
    }

    if (permission != LocationPermission.always) {
      throw ServerException('Se requiere permiso de ubicación en segundo plano (Always) para el seguimiento de fondo.');
    }

    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw ServerException('Se requiere un token de autenticación para iniciar el seguimiento en segundo plano.');
    }

    final endpoint = '${AppConfig.apiBaseUrl}${ApiConstants.serenazgoTrackingLocation}';
    await _service.start(token, endpoint);
  }

  @override
  Future<void> stopBackgroundTracking() async {
    await _service.stop();
  }
}
