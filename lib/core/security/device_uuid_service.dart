import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceUuidService {
  static const _deviceUuidKey = 'device_uuid';

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  DeviceUuidService(this._secureStorage, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<String> getOrCreate() async {
    final current = await _secureStorage.read(key: _deviceUuidKey);
    if (current != null && current.isNotEmpty) {
      return current;
    }

    final generated = _uuid.v4();
    await _secureStorage.write(key: _deviceUuidKey, value: generated);
    return generated;
  }
}
