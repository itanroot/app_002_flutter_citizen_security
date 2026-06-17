import '../models/sos_model.dart';

abstract class SosRemoteDataSource {
  Future<void> sendSOS(SosModel sos);
}
