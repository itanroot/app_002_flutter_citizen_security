/// Centraliza todos los endpoints REST del backend.
/// No hardcodear rutas fuera de esta clase.
final class ApiConstants {
  ApiConstants._();

  //  Versión
  static const String _v1 = '/api/v1';

  //  Auth
  static const String login  = '$_v1/auth/login';
  static const String register = '$_v1/auth/register';
  static const String logout = '$_v1/auth/logout';
  static const String profile     = '$_v1/auth/me';

  //  User
  static const String userTrackingLocation     = '$_v1/user/tracking/location';

  // Incidents
  static const String incidentSos     = '$_v1/incidents/sos';  

  //  Serenazgo

  // GET — Incidencias activas para el mapa.
  static const String serenazgoIncidentsMap = '$_v1/serenazgo/incidents/map';

  /// GET — Detalle de una incidencia.
  static String serenazgoIncidentDetail(int id) =>
      '$_v1/serenazgo/incidents/$id';

  //  WebSocket — Canales Reverb

  /// Canal privado por municipio.
  static String serenazgoChannel(int municipalityId) =>
      'channel-serenazgo.municipality.$municipalityId';

  //  WebSocket — Nombres de eventos

  static const String eventIncidentCreated = 'IncidentCreated';
}