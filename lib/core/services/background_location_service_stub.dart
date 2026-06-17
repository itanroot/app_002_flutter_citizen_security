class BackgroundLocationService {
  Future<void> start(String token, String endpoint) async {}
  Future<void> stop() async {}
  Stream<Map<String, dynamic>> get onLocationChanged => const Stream.empty();
}
