import 'package:flutter/services.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';

class BackgroundLocationService {
  static const _channel = MethodChannel('com.example.seguridad_ciudadana_app/background_location');
  static const _eventChannel = EventChannel('com.example.seguridad_ciudadana_app/background_location_events');

  Future<void> start(String token, String endpoint) async {
    /*final hasForegroundServiceLocationPermission = await _channel.invokeMethod<bool>(
      'requestForegroundServiceLocationPermission',
    );

    if (hasForegroundServiceLocationPermission != true) {
      throw ServerException('Se requiere permiso de servicio en primer plano para ubicación antes de iniciar el seguimiento de fondo.');
    }*/

    try {
      await _channel.invokeMethod('start', {
        'token': token,
        'endpoint': endpoint,
      });
    } on PlatformException catch (e) {
      throw ServerException(e.message ?? 'Unable to start background tracking.');
    }
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  Stream<Map<String, dynamic>> get onLocationChanged {
    return _eventChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();
  }
}
