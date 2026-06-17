import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<void> sendLocation(LocationModel location);
}
