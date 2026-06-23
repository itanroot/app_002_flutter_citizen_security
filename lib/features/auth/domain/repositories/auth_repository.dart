import "package:dartz/dartz.dart";
import "package:seguridad_ciudadana_app/core/errors/failure.dart";
import "../entities/user_entity.dart";

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String username, String password);
  Future<Either<Failure, UserEntity>> register(String name, String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
