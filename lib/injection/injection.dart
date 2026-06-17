import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seguridad_ciudadana_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:seguridad_ciudadana_app/features/auth/data/datasources/auth_local_data_source_impl.dart';
import 'package:seguridad_ciudadana_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/core/network/dio_client.dart';
import 'package:seguridad_ciudadana_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:seguridad_ciudadana_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:seguridad_ciudadana_app/core/security/secure_storage_service.dart';
import 'package:seguridad_ciudadana_app/features/location/data/datasources/location_remote_data_source.dart';
import 'package:seguridad_ciudadana_app/features/location/data/datasources/location_remote_data_source_impl.dart';
import 'package:seguridad_ciudadana_app/features/location/data/repositories/location_repository_impl.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/repositories/location_repository.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/start_location_tracking_usecase.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/stop_location_tracking_usecase.dart';
import 'package:seguridad_ciudadana_app/features/location/domain/usecases/watch_location_updates_usecase.dart';
import 'package:seguridad_ciudadana_app/core/services/background_location_service.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/datasources/background_location_data_source.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/datasources/background_location_data_source_impl.dart';
import 'package:seguridad_ciudadana_app/features/background_location/data/repositories/background_location_repository_impl.dart';
import 'package:seguridad_ciudadana_app/features/background_location/domain/repositories/background_location_repository.dart';
import 'package:seguridad_ciudadana_app/features/background_location/domain/usecases/start_background_location_usecase.dart';
import 'package:seguridad_ciudadana_app/features/background_location/domain/usecases/stop_background_location_usecase.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthLocalDataSourceImpl(secureStorage);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final local = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remote, local);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return LocationRemoteDataSourceImpl(dio);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(ref.watch(locationRemoteDataSourceProvider));
});

final startLocationTrackingUseCaseProvider = Provider<StartLocationTrackingUseCase>((ref) {
  return StartLocationTrackingUseCase(ref.watch(locationRepositoryProvider));
});

final stopLocationTrackingUseCaseProvider = Provider<StopLocationTrackingUseCase>((ref) {
  return StopLocationTrackingUseCase(ref.watch(locationRepositoryProvider));
});

final watchLocationUpdatesUseCaseProvider = Provider<WatchLocationUpdatesUseCase>((ref) {
  return WatchLocationUpdatesUseCase(ref.watch(locationRepositoryProvider));
});

final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService();
});

final backgroundLocationDataSourceProvider = Provider<BackgroundLocationDataSource>((ref) {
  return BackgroundLocationDataSourceImpl(ref.watch(backgroundLocationServiceProvider), ref.watch(secureStorageProvider));
});

final backgroundLocationRepositoryProvider = Provider<BackgroundLocationRepository>((ref) {
  return BackgroundLocationRepositoryImpl(ref.watch(backgroundLocationDataSourceProvider));
});

final startBackgroundLocationUseCaseProvider = Provider<StartBackgroundLocationUseCase>((ref) {
  return StartBackgroundLocationUseCase(ref.watch(backgroundLocationRepositoryProvider));
});

final stopBackgroundLocationUseCaseProvider = Provider<StopBackgroundLocationUseCase>((ref) {
  return StopBackgroundLocationUseCase(ref.watch(backgroundLocationRepositoryProvider));
});

