import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import 'package:seguridad_ciudadana_app/core/constants/api_constants.dart';
import 'package:seguridad_ciudadana_app/core/config/websocket_config.dart';

typedef SerenazgoLocationCallback = FutureOr<void> Function({
  required int serenazgoId,
  required double latitude,
  required double longitude,
});

enum SerenazgoLocationConnectionResult {
  connected,
  skippedMissingAuth,
  failed,
}

/// Escucha actualizaciones de ubicación de serenazgo en tiempo real a través
class SerenazgoLocationRealtimeService {
  SerenazgoLocationRealtimeService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  ReverbClient? _client;
  PrivateChannel? _channel;
  StreamSubscription<ChannelEvent>? _eventSubscription;
  String? _currentChannelName;
  bool _initialized = false;
  int _listenerGeneration = 0;

  bool get isConnected => _initialized && _channel != null;

  String _buildWebSocketTargetUrl() {
    final wsScheme = WebSocketConfig.useTls ? 'wss' : 'ws';
    return '$wsScheme://${WebSocketConfig.host}:${WebSocketConfig.port}/app/${WebSocketConfig.appKey}';
  }

  Map<String, dynamic>? _parseData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _bindLocationListener(SerenazgoLocationCallback onLocation) async {
    _listenerGeneration++;
    final generation = _listenerGeneration;

    await _eventSubscription?.cancel();

    if (_channel == null) {
      return;
    }

    _eventSubscription = _channel!.stream.listen((event) async {
      if (generation != _listenerGeneration) {
        return;
      }

      final normalized = event.eventName.trim().toLowerCase();
      if (!normalized.contains(ApiConstants.eventSerenazgoLocationUpdated)) {
        return;
      }

      final payload = _parseData(event.data);
      if (payload == null) {
        return;
      }

      final serenazgoIdFromPayload = (payload['serenazgo_id'] as num?)?.toInt();
      final serenazgoProfileId = (payload['serenazgo_profile_id'] as num?)?.toInt();
      final rawLat = payload['latitude'];
      final rawLng = payload['longitude'];

      final serenazgoId = serenazgoIdFromPayload ?? serenazgoProfileId;

      if (serenazgoId == null || rawLat == null || rawLng == null) {
        return;
      }

      final latitude = rawLat is num
          ? rawLat.toDouble()
          : double.tryParse(rawLat.toString());
      final longitude = rawLng is num
          ? rawLng.toDouble()
          : double.tryParse(rawLng.toString());

      if (latitude == null || longitude == null) {
        return;
      }

      try {
        await Future.sync(
          () => onLocation(
            serenazgoId: serenazgoId,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> _waitUntilConnected(ReverbClient client) async {
    if (client.connectionState == ConnectionState.connected) {
      return;
    }

    final completer = Completer<void>();
    late final StreamSubscription<ConnectionState> sub;
    sub = client.onConnectionStateChange.listen((state) {
      if (!completer.isCompleted && state == ConnectionState.connected) {
        completer.complete();
      }
      if (!completer.isCompleted && state == ConnectionState.error) {
        completer.completeError(
          StateError('Websocket entered error state before connecting.'),
        );
      }
    });

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Timed out waiting websocket connection for serenazgo location channel.',
        ),
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<SerenazgoLocationConnectionResult> connectToMunicipality({
    required int municipalityId,
    required SerenazgoLocationCallback onLocationUpdated,
  }) async {
    final channelName =
        'private-${ApiConstants.serenazgoLocationChannel(municipalityId)}';

    if (_initialized && _currentChannelName == channelName) {
      await _bindLocationListener(onLocationUpdated);
      return SerenazgoLocationConnectionResult.connected;
    }

    await disconnect();

    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      return SerenazgoLocationConnectionResult.skippedMissingAuth;
    }

    _buildWebSocketTargetUrl();

    _client = ReverbClient.instance(
      host: WebSocketConfig.host,
      port: WebSocketConfig.port,
      appKey: WebSocketConfig.appKey,
      useTLS: WebSocketConfig.useTls,
      authorizer: (String authChannelName, String socketId) async {
        return {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
      },
      authEndpoint: WebSocketConfig.authEndpoint,
      onConnecting: () {},
      onConnected: (socketId) {},
      onReconnecting: () {},
      onDisconnected: () {},
      onError: (error) {},
    );

    try {
      await _client!.connect();

      await _waitUntilConnected(_client!);

      _channel = _client!.subscribeToPrivateChannel(channelName);

      final subscriptionCompleter = Completer<void>();
      late final ChannelStateListener stateListener;
      stateListener = (state) {
        if (!subscriptionCompleter.isCompleted &&
            state == ChannelState.subscribed) {
          subscriptionCompleter.complete();
        }
        if (!subscriptionCompleter.isCompleted &&
            state == ChannelState.unsubscribed) {
          subscriptionCompleter.completeError(
            StateError(
              'Channel moved to unsubscribed before confirmation.',
            ),
          );
        }
      };

      _channel!.addStateListener(stateListener);

      try {
        await subscriptionCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
            'Timed out waiting subscription_succeeded for $channelName.',
          ),
        );
      } finally {
        _channel?.removeStateListener(stateListener);
      }

      await _bindLocationListener(onLocationUpdated);

      _currentChannelName = channelName;
      _initialized = true;
      return SerenazgoLocationConnectionResult.connected;
    } catch (_) {
      await disconnect();
      return SerenazgoLocationConnectionResult.failed;
    }
  }

  Future<void> disconnect() async {
    _listenerGeneration++;

    try {
      await _eventSubscription?.cancel();
    } catch (_) {}

    if (_channel != null) {
      try {
        await _channel!.unsubscribe();
      } catch (_) {}
    }

    try {
      _client?.disconnect();
    } catch (_) {}

    _eventSubscription = null;
    _channel = null;
    _client = null;
    _currentChannelName = null;
    _initialized = false;
  }

  Future<void> detachListener() async {
    _listenerGeneration++;

    try {
      await _eventSubscription?.cancel();
    } catch (_) {}

    _eventSubscription = null;
  }
}
