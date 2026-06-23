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

  UserEntity _mapUser(UserEntity user) => user;

  UserEntity _mapUserModel(userModel) {
    return UserEntity(
      id: userModel.id,
      username: userModel.username,
      email: userModel.email,
      municipalityId: userModel.municipalityId,
      roles: userModel.roles,
      permissions: userModel.permissions,
    );
  }

  @override
  Future<Either<Failure, UserEntity>> login(String username, String password) async {
    try {
      final result = await remoteDataSource.login(username, password);
      await localDataSource.saveToken(result.token);
      return Right(_mapUserModel(result.user));
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(String name, String email, String password) async {
    try {
      final result = await remoteDataSource.register(name, email, password);
      return Right(_mapUserModel(result.user));
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    Failure? remoteFailure;

    try {
      await remoteDataSource.logout();
    } on ServerException catch (e) {
      remoteFailure = ApiFailure(e.message);
    } catch (e) {
      remoteFailure = ApiFailure(e.toString());
    }

    await localDataSource.deleteToken();

    if (remoteFailure != null) {
      return Left(remoteFailure);
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(_mapUserModel(result));
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }
}
