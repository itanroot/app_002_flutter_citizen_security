import 'package:flutter_dotenv/flutter_dotenv.dart';

final class AppConfig {
  AppConfig._();

  static bool _loaded = false;

  /// Debe llamarse en [main] antes de [runApp].
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  // API REST

  static String get apiBaseUrl => _get('API_URL');

  // Laravel Reverb / Pusher 

  static String get reverbAppKey => _get('REVERB_APP_KEY');
  static String get reverbHost   => _get('REVERB_HOST');
  static int    get reverbPort   => int.parse(_get('REVERB_PORT'));
  static String get reverbScheme => _get('REVERB_SCHEME');

  // Google Maps

  static String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');

  // Helper privado

  static String _get(String key) {
    if (!_loaded) {
      throw StateError(
        'AppConfig no ha sido inicializado. '
        'Llama AppConfig.load() antes de usar la app.',
      );
    }
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Variable de entorno "$key" no encontrada en .env');
    }
    return value;
  }
}