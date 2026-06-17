import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/entities/location_entity.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/repositories/location_repository.dart';

class WatchLocationUpdatesUseCase {
  final LocationRepository repository;

  WatchLocationUpdatesUseCase(this.repository);

  Stream<Either<Failure, LocationEntity>> execute() {
    return repository.watchLocationUpdates();
  }
}
