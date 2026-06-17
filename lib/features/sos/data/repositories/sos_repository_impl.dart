import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/api_failure.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/sos/data/datasources/sos_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/sos/data/models/sos_model.dart';
import 'package:seguridad_ciudadana_app/features/sos/domain/entities/sos_entity.dart';
import 'package:seguridad_ciudadana_app/features/sos/domain/repositories/sos_repository.dart';

class SosRepositoryImpl implements SosRepository {
  final SosRemoteDataSource remoteDataSource;

  SosRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> sendSOS(SosEntity sos) async {
    try {
      final sosModel = SosModel.fromEntity(sos);
      await remoteDataSource.sendSOS(sosModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }
}
