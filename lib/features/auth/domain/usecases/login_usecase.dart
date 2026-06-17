import "package:seguridad_ciudadana_app/core/errors/failure.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/repositories/auth_repository.dart";
import "package:dartz/dartz.dart";

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Either<Failure, String>> execute(String username, String password) {
    return repository.login(username, password);
  }
}
