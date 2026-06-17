import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/api_failure.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/datasources/background_location_data_source.dart';
import 'package:seguridad_ciudadana_app/features/background_location/domain/repositories/background_location_repository.dart';

class BackgroundLocationRepositoryImpl implements BackgroundLocationRepository {
  final BackgroundLocationDataSource _dataSource;

  BackgroundLocationRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, void>> startBackgroundTracking() async {
    try {
      await _dataSource.startBackgroundTracking();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Unable to start background tracking.'));
    }
  }

  @override
  Future<Either<Failure, void>> stopBackgroundTracking() async {
    try {
      await _dataSource.stopBackgroundTracking();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Unable to stop background tracking.'));
    }
  }
}
