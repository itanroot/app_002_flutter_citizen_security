import "package:seguridad_ciudadana_app/features/auth/data/models/auth_model.dart";
import "package:seguridad_ciudadana_app/features/auth/data/models/user_model.dart";

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String username, String password);
  Future<AuthModel> register(String name, String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}
