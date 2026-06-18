import 'app_config.dart';

/// Parámetros de conexión para Laravel Reverb.
/// Reverb implementa el protocolo Pusher, por lo que usamos
/// pusher_channels_flutter + laravel_echo.
final class WebSocketConfig {
  WebSocketConfig._();

  // ─── Conexión ──────────────────────────────────────────────────────────────

  static String get appKey  => AppConfig.reverbAppKey;
  static String get host    => AppConfig.reverbHost;
  static int    get port    => AppConfig.reverbPort;
  static String get scheme  => AppConfig.reverbScheme;

  /// `true` cuando el esquema es wss (producción).
  static bool get useTls    => scheme == 'wss' || scheme == 'https';

  // ─── Configuración Pusher compatible con Reverb ────────────────────────────

  /// Opciones del cluster — Reverb no usa cluster real,
  /// pero la librería Pusher lo requiere.
  static const String cluster = 'mt1';

  /// Endpoint de autenticación de canales privados.
  /// Reverb valida el JWT del usuario aquí.
  static String get authEndpoint => '${AppConfig.apiBaseUrl}/broadcasting/auth';

  // ─── Reconexión ───────────────────────────────────────────────────────────

  static const Duration reconnectDelay   = Duration(seconds: 3);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  static const int      maxReconnectAttempts = 10;

  // ─── Resumen para depuración (sin exponer key) ────────────────────────────
  @override
  String toString() =>
      'WebSocketConfig(host: $host, port: $port, tls: $useTls)';
}