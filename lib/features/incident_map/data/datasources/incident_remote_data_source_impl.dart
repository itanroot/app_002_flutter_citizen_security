import 'package:dio/dio.dart';
import 'package:seguridad_ciudadana_app/core/constants/api_constants.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/datasources/incident_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/data/models/incident_model.dart';

class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  final Dio dio;

  IncidentRemoteDataSourceImpl(this.dio);

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
}
