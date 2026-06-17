import 'package:dio/dio.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/features/location/data/datasources/location_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/location/data/models/location_model.dart';

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio dio;

  LocationRemoteDataSourceImpl(this.dio);

  @override
  Future<void> sendLocation(LocationModel location) async {
    try {
      await dio.post(
        '/tracking/location',
        data: location.toJson(),
      );
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to send location to backend');
    }
  }
}
