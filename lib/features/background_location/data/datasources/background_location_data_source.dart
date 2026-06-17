abstract class BackgroundLocationDataSource {
  Future<void> startBackgroundTracking();
  Future<void> stopBackgroundTracking();
}
