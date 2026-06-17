import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import '../entities/sos_entity.dart';

abstract class SosRepository {
  Future<Either<Failure, void>> sendSOS(SosEntity sos);
}
