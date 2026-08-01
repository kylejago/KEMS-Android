import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_config.dart';
import '../models/ha_entity.dart';

class HomeAssistantSocket {
  HomeAssistantSocket(this.config);

  final AppConfig config;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _messageId = 1;
  bool _intentionalClose = false;

  Uri get _socketUri {
    final base = Uri.parse(config.normalizedBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/api/websocket',
      query: null,
      fragment: null,
    );
  }

  Future<void> connect({
    required void Function(HaEntity entity) onStateChanged,
    required void Function(bool connected) onConnection,
    required void Function(Object error) onError,
  }) async {
    await disconnect();
    _intentionalClose = false;
    final channel = WebSocketChannel.connect(_socketUri);
    _channel = channel;

    try {
      await channel.ready.timeout(const Duration(seconds: 12));
    } catch (error) {
      await channel.sink.close();
      if (!_intentionalClose) onError(error);
      rethrow;
    }

    _subscription = channel.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        switch (data['type']) {
          case 'auth_required':
            channel.sink.add(jsonEncode({
              'type': 'auth',
              'access_token': config.token,
            }));
            break;
          case 'auth_ok':
            onConnection(true);
            channel.sink.add(jsonEncode({
              'id': _messageId++,
              'type': 'subscribe_events',
              'event_type': 'state_changed',
            }));
            break;
          case 'auth_invalid':
            onConnection(false);
            onError(Exception('Home Assistant WebSocket authentication failed.'));
            break;
          case 'event':
            final event = data['event'] as Map<String, dynamic>?;
            final eventData = event?['data'] as Map<String, dynamic>?;
            final newState = eventData?['new_state'] as Map<String, dynamic>?;
            if (newState != null) onStateChanged(HaEntity.fromJson(newState));
            break;
        }
      },
      onError: (Object error) {
        onConnection(false);
        if (!_intentionalClose) onError(error);
      },
      onDone: () {
        onConnection(false);
        if (!_intentionalClose) {
          onError(Exception('Live connection closed. Reconnecting…'));
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    _intentionalClose = true;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
