import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seguridad_ciudadana_app/core/errors/api_failure.dart';
import 'package:seguridad_ciudadana_app/core/errors/exceptions.dart';
import 'package:seguridad_ciudadana_app/core/errors/failure.dart';
import 'package:seguridad_ciudadana_app/features/location/data/datasources/location_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/location/data/models/location_model.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/entities/location_entity.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final StreamController<Either<Failure, LocationEntity>> _locationUpdatesController;
  StreamSubscription<Position>? _positionSubscription;

  LocationRepositoryImpl(this.remoteDataSource)
      : _locationUpdatesController = StreamController<Either<Failure, LocationEntity>>.broadcast();

  @override
  Stream<Either<Failure, LocationEntity>> watchLocationUpdates() {
    return _locationUpdatesController.stream;
  }

  @override
  Future<Either<Failure, void>> startTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ServerException('Location services are disabled. Please enable them.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw ServerException('Location permission denied. Grant access to continue.');
      }

      if (_positionSubscription != null) {
        return const Right(null);
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      ).listen(
        (position) async {
          try {
            final locationModel = LocationModel(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now().toUtc(),
            );

            await remoteDataSource.sendLocation(locationModel);

            _locationUpdatesController.add(
              Right(
                LocationEntity(
                  latitude: locationModel.latitude,
                  longitude: locationModel.longitude,
                  timestamp: locationModel.timestamp,
                ),
              ),
            );
          } catch (e) {
            _locationUpdatesController.add(Left(ApiFailure(e is ServerException ? e.message : 'Unable to send location')));
          }
        },
        onError: (error) {
          final message = error is PermissionDeniedException
              ? 'Location permission denied by the system.'
              : error is LocationServiceDisabledException
                  ? 'Location services are disabled.'
                  : 'Failed to obtain location updates.';
          _locationUpdatesController.add(Left(ApiFailure(message)));
        },
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopTracking() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      return const Right(null);
    } catch (e) {
      return Left(ApiFailure('Unable to stop location tracking.'));
    }
  }
}
