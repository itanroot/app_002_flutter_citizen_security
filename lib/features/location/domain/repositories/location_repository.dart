import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import '../entities/location_entity.dart';

abstract class LocationRepository {
  Future<Either<Failure, void>> startTracking();
  Future<Either<Failure, void>> stopTracking();
  Stream<Either<Failure, LocationEntity>> watchLocationUpdates();
}
