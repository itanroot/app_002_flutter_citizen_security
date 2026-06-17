abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<String?> getToken();
}
