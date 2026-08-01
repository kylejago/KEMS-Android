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

  Uri get _socketUri {
    final base = Uri.parse(config.normalizedBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/api/websocket',
    );
  }

  Future<void> connect({
    required void Function(HaEntity entity) onStateChanged,
    required void Function(bool connected) onConnection,
    required void Function(Object error) onError,
  }) async {
    await disconnect();
    final channel = WebSocketChannel.connect(_socketUri);
    _channel = channel;
    _subscription = channel.stream.listen((raw) {
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
          onError(Exception('Home Assistant authentication failed.'));
          break;
        case 'event':
          final event = data['event'] as Map<String, dynamic>?;
          final eventData = event?['data'] as Map<String, dynamic>?;
          final newState = eventData?['new_state'] as Map<String, dynamic>?;
          if (newState != null) onStateChanged(HaEntity.fromJson(newState));
          break;
      }
    }, onError: (Object error) {
      onConnection(false);
      onError(error);
    }, onDone: () => onConnection(false));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
