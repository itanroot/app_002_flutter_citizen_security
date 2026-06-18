import 'package:dio/dio.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import "package:seguridad_ciudadana_app/core/constants/api_constants.dart";
import 'package:seguridad_ciudadana_app/features/sos/data/datasources/sos_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/sos/data/models/sos_model.dart';

class SosRemoteDataSourceImpl implements SosRemoteDataSource {
  final Dio dio;

  SosRemoteDataSourceImpl(this.dio);

  @override
  Future<void> sendSOS(SosModel sos) async {
    try {
      await dio.post(
        ApiConstants.incidentSos,
        data: sos.toJson(),
      );
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to send SOS');
    }
  }
}
