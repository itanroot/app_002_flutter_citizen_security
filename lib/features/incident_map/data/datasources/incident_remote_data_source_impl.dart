import 'package:dio/dio.dart';
import 'package:seguridad_ciudadana_app/core/constants/api_constants.dart';
import 'package:seguridad_ciudadana_app/core/constants/incident_taxonomy.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/datasources/incident_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/models/incident_model.dart';

class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  final Dio dio;

  IncidentRemoteDataSourceImpl(this.dio);

  String _extractErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final directMessage = data['message'] ?? data['error'] ?? data['result'];
      if (directMessage is String && directMessage.trim().isNotEmpty) {
        return directMessage;
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first;
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    }

    final fallback = e.message ?? 'No se pudo atender la incidencia SOS';
    return statusCode != null ? '[$statusCode] $fallback' : fallback;
  }

  List<IncidentModel> _parseIncidents(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      final incidents = rawData['incidents'];
      if (incidents is List) {
        return incidents
            .whereType<Map<String, dynamic>>()
            .map(IncidentModel.fromJson)
            .toList();
      }
      return const <IncidentModel>[];
    }

    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(IncidentModel.fromJson)
          .toList();
    }

    return const <IncidentModel>[];
  }

  @override
  Future<List<IncidentModel>> fetchAllIncidents() async {
    final response = await dio.get(ApiConstants.incidents);
    return _parseIncidents(response.data);
  }

  @override
  Future<List<IncidentModel>> fetchPendingIncidents() async {
    final response = await dio.get(ApiConstants.incidents, queryParameters: {'status': 'open'});
    return _parseIncidents(response.data);
  }

  @override
  Future<List<IncidentModel>> fetchMyIncidents({String? deviceUuid}) async {
    final response = await dio.get(
      ApiConstants.incidentMy,
      queryParameters: deviceUuid != null && deviceUuid.isNotEmpty
          ? {'device_uuid': deviceUuid}
          : null,
    );
    return _parseIncidents(response.data);
  }

  @override
  Future<void> attendSosIncident({required int incidentId, required int userId}) async {
    try {
      await dio.post(
        ApiConstants.incidentSosDetail(incidentId),
        data: {
          'status': IncidentStateNames.inRoute,
          'user_id': userId,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    }
  }
}
