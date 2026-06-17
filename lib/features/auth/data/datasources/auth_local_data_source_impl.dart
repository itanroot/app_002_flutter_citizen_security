import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_local_data_source.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const _tokenKey = 'auth_token';

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<String?> getToken() async {
    return secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> deleteToken() async {
    await secureStorage.delete(key: _tokenKey);
  }
}
