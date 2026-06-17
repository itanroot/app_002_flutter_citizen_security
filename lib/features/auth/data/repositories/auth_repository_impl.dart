import "package:dartz/dartz.dart";
import "package:seguridad_ciudadana_app/core/errors/failure.dart";
import "package:seguridad_ciudadana_app/core/errors/api_failure.dart";
import "package:seguridad_ciudadana_app/core/errors/exceptions.dart";
import "package:seguridad_ciudadana_app/features/auth/data/datasources/auth_local_data_source.dart";
import "package:seguridad_ciudadana_app/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/entities/user_entity.dart";
import "package:seguridad_ciudadana_app/features/auth/domain/repositories/auth_repository.dart";

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, String>> login(String username, String password) async {
    try {
      final result = await remoteDataSource.login(username, password);
      await localDataSource.saveToken(result.token);
      return Right(result.token);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(String name, String email, String password) async {
    try {
      final result = await remoteDataSource.register(name, email, password);
      final userModel = result.user;
      return Right(UserEntity(id: userModel.id, username: userModel.username, email: userModel.email));
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.deleteToken();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(UserEntity(id: result.id, username: result.username, email: result.email));
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }
}
