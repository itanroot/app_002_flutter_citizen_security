import "package:seguridad_ciudadana_app/core/errors/failure.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/repositories/auth_repository.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/entities/user_entity.dart";
import "package:dartz/dartz.dart";

class GetCurrentUserUseCase {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute() {
    return repository.getCurrentUser();
  }
}
