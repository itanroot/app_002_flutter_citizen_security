import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import 'package:seguridad_ciudadana_app/core/constants/api_constants.dart';
import 'package:seguridad_ciudadana_app/core/config/websocket_config.dart';

typedef IncidentCreatedCallback = FutureOr<void> Function();

class IncidentRealtimeService {
  IncidentRealtimeService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  ReverbClient? _client;
  PrivateChannel? _channel;
  StreamSubscription<ChannelEvent>? _eventSubscription;
  String? _currentChannelName;
  bool _initialized = false;
  int _listenerGeneration = 0;

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  bool _shouldRefreshForEvent(String eventName) {
    final normalized = eventName.trim().toLowerCase();

    // Accept both legacy and current backend event naming styles.
    const exactMatches = <String>{
      'incidentcreated',
      'new.incident',
      'incident.created',
      'incident_created',
      'new_incident',
    };

    if (exactMatches.contains(normalized)) {
      return true;
    }

    final mentionsIncident = normalized.contains('incident');
    final mentionsCreation =
        normalized.contains('new') || normalized.contains('create');

    return mentionsIncident && mentionsCreation;
  }

  String _buildWebSocketTargetUrl() {
    final wsScheme = WebSocketConfig.useTls ? 'wss' : 'ws';
    return '$wsScheme://${WebSocketConfig.host}:${WebSocketConfig.port}/app/${WebSocketConfig.appKey}';
  }

  Future<void> _bindIncidentListener(IncidentCreatedCallback onIncidentCreated) async {
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

      final eventName = event.eventName;
      if (_shouldRefreshForEvent(eventName) ||
          eventName.contains(ApiConstants.eventIncidentCreated)) {
        _logDebug(
          '[Realtime] Incident event matched ($eventName) -> refreshing incidents',
        );
        try {
          await Future.sync(onIncidentCreated);
        } catch (e, st) {
          _logDebug('[Realtime][WARN] Refresh callback ignored: $e');
          _logDebug('[Realtime][WARN] stack: $st');
        }
      }
    });
  }

  Future<void> connectToMunicipality({
    required int municipalityId,
    required IncidentCreatedCallback onIncidentCreated,
  }) async {
    final channelName = 'private-${ApiConstants.serenazgoChannel(municipalityId)}';

    if (_initialized && _currentChannelName == channelName) {
      _logDebug('[Realtime] Reusing connected channel and rebinding listener.');
      await _bindIncidentListener(onIncidentCreated);
      return;
    }

    await disconnect();

    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _logDebug('Reverb/Pusher skipped: auth_token not found in secure storage.');
      return;
    }

    final wsTarget = _buildWebSocketTargetUrl();
    _logDebug('[Realtime] WS connect target: $wsTarget');
    _logDebug('[Realtime] Auth endpoint: ${WebSocketConfig.authEndpoint}');
    if (WebSocketConfig.authEndpoint.contains('localhost')) {
      _logDebug(
        '[Realtime][WARN] authEndpoint usa localhost. En dispositivo fisico, localhost apunta al telefono, no al backend.',
      );
    }

    final connectedCompleter = Completer<void>();

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
      onConnecting: () {
        _logDebug('Reverb state: connecting');
      },
      onConnected: (socketId) {
        _logDebug('Reverb state: connected ($socketId)');
        if (!connectedCompleter.isCompleted) {
          connectedCompleter.complete();
        }
      },
      onReconnecting: () {
        _logDebug('Reverb state: reconnecting');
      },
      onDisconnected: () {
        _logDebug('Reverb state: disconnected');
      },
      onError: (error) {
        _logDebug('Reverb error: $error');
        if (!connectedCompleter.isCompleted) {
          connectedCompleter.completeError(error);
        }
      },
    );

    try {
      await _client!.connect();

      await connectedCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Timed out waiting websocket connection before private subscribe.',
        ),
      );

      _channel = _client!.subscribeToPrivateChannel(channelName);
      _logDebug('[Realtime] Subscribe requested for channel: $channelName');

      final subscriptionCompleter = Completer<void>();
      late final ChannelStateListener stateListener;
      stateListener = (state) {
        _logDebug('[Realtime] Channel state -> $channelName: $state');
        if (!subscriptionCompleter.isCompleted && state == ChannelState.subscribed) {
          subscriptionCompleter.complete();
        }
        if (!subscriptionCompleter.isCompleted && state == ChannelState.unsubscribed) {
          subscriptionCompleter.completeError(
            StateError('Channel moved to unsubscribed before subscription was confirmed.'),
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
        _logDebug('[Realtime] Private subscription confirmed: $channelName');
      } finally {
        _channel?.removeStateListener(stateListener);
      }

      await _bindIncidentListener(onIncidentCreated);

      _currentChannelName = channelName;
      _initialized = true;
    } catch (e, st) {
      _logDebug('[Realtime][ERROR] connect/subscribe failed: $e');
      _logDebug('[Realtime][ERROR] stack: $st');
      await disconnect();
    }
  }

  Future<void> disconnect() async {
    // Invalidate any already-captured listener callback immediately.
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
    // Invalidate any already-captured listener callback immediately.
    _listenerGeneration++;

    try {
      await _eventSubscription?.cancel();
    } catch (_) {}

    _eventSubscription = null;
  }
}
