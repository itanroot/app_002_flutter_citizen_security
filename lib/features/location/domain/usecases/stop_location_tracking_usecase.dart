import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/repositories/location_repository.dart';

class StopLocationTrackingUseCase {
  final LocationRepository repository;

  StopLocationTrackingUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.stopTracking();
  }
}
