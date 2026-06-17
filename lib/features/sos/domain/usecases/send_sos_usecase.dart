import 'package:dartz/dartz.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import '../entities/sos_entity.dart';
import '../repositories/sos_repository.dart';

class SendSosUseCase {
  final SosRepository repository;

  SendSosUseCase(this.repository);

  Future<Either<Failure, void>> execute(SosEntity sos) {
    return repository.sendSOS(sos);
  }
}
