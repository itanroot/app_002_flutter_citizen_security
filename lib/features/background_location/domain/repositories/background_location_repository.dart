import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';

abstract class BackgroundLocationRepository {
  Future<Either<Failure, void>> startBackgroundTracking();
  Future<Either<Failure, void>> stopBackgroundTracking();
}
