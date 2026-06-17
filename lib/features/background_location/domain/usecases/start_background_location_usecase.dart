import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import '../repositories/background_location_repository.dart';

class StartBackgroundLocationUseCase {
  final BackgroundLocationRepository repository;

  StartBackgroundLocationUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.startBackgroundTracking();
  }
}
