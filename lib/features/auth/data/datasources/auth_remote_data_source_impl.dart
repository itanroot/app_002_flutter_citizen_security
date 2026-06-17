import "package:dio/dio.dart";
import "package:seguridad_ciudadana_app/core/errors/exceptions.dart";
import "package:seguridad_ciudadana_app/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:seguridad_ciudadana_app/features/auth/data/models/auth_model.dart";
import "package:seguridad_ciudadana_app/features/auth/data/models/user_model.dart";

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<AuthModel> login(String username, String password) async {
    try {
      final response = await dio.post(
        "/auth/login",
        data: {"username": username, "password": password},
      );
      return AuthModel.fromJson(response.data["data"]);
    } on DioException catch (e) {
      final data = e.response?.data;

      String message = "Error de autenticación";

      if (data is Map<String, dynamic>) {
        message = data["message"] ?? message;
      }

      throw ServerException(message);
    }
  }

  @override
  Future<AuthModel> register(String name, String email, String password) async {
    try {
      final response = await dio.post(
        "/auth/register",
        data: {"name": name, "email": email, "password": password},
      );
      return AuthModel.fromJson(response.data["data"]);
    } on DioException catch (e) {
      throw ServerException(e.message ?? "Registration failed");
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post("/auth/logout");
    } on DioException catch (e) {
      throw ServerException(e.message ?? "Logout failed");
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get("/auth/me");
      return UserModel.fromJson(response.data["data"]);
    } on DioException catch (e) {
      throw ServerException(e.message ?? "Failed to fetch user");
    }
  }
}
