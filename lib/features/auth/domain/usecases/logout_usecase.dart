import "package:seguridad_ciudadana_app/core/errors/failure.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/repositories/auth_repository.dart";
import "package:dartz/dartz.dart";

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.logout();
  }
}
