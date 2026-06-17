import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/repositories/location_repository.dart';

class StartLocationTrackingUseCase {
  final LocationRepository repository;

  StartLocationTrackingUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.startTracking();
  }
}
