import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_config.dart';
import '../models/entity_mapping.dart';
import '../models/ha_entity.dart';
import '../services/home_assistant_api.dart';
import '../services/home_assistant_socket.dart';
import '../services/secure_config_store.dart';

class AppController extends ChangeNotifier {
  AppController({SecureConfigStore? store}) : _store = store ?? SecureConfigStore();

  final SecureConfigStore _store;
  final EntityMapping mapping = const EntityMapping();
  AppConfig? config;
  HomeAssistantApi? api;
  HomeAssistantSocket? socket;
  final Map<String, HaEntity> entities = {};
  bool loading = true;
  bool connected = false;
  String? error;
  DateTime? lastUpdated;

  Timer? _reconnectTimer;
  bool _shuttingDown = false;

  bool get configured => config != null;
  HaEntity? entity(String id) => entities[id];
  List<HaEntity> get kemsEntities => entities.values
      .where(
        (e) =>
            e.entityId.startsWith('sensor.kems_') ||
            e.entityId.startsWith('binary_sensor.kems_'),
      )
      .toList()
    ..sort((a, b) => a.entityId.compareTo(b.entityId));

  bool isOn(String id) => entity(id)?.state == 'on';
  bool isAvailable(String id) {
    final state = entity(id)?.state;
    return state != null && state != 'unknown' && state != 'unavailable';
  }

  Future<void> initialise() async {
    config = await _store.read();
    if (config != null) await _startConnection();
    loading = false;
    notifyListeners();
  }

  Future<bool> saveConfiguration(String url, String token) async {
    loading = true;
    error = null;
    notifyListeners();
    final candidate = AppConfig(baseUrl: url, token: token);
    final candidateApi = HomeAssistantApi(candidate);
    try {
      await candidateApi.validateConnection();
      await _store.write(candidate);
      config = candidate;
      await _startConnection();
      return true;
    } catch (exception) {
      error = _friendlyError(exception);
      return false;
    } finally {
      candidateApi.close();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _startConnection() async {
    final current = config;
    if (current == null) {
      return;
    }
    _shuttingDown = false;
    _reconnectTimer?.cancel();
    api?.close();
    api = HomeAssistantApi(current);
    socket = HomeAssistantSocket(current);
    try {
      final states = await api!.getStates();
      entities
        ..clear()
        ..addEntries(states.map((e) => MapEntry(e.entityId, e)));
      lastUpdated = DateTime.now();
      error = null;
      await _connectSocket();
    } catch (exception) {
      connected = false;
      error = _friendlyError(exception);
      _scheduleReconnect();
    }
  }

  Future<void> _connectSocket() async {
    final currentSocket = socket;
    if (currentSocket == null || _shuttingDown) {
      return;
    }
    try {
      await currentSocket.connect(
        onStateChanged: (entity) {
          entities[entity.entityId] = entity;
          lastUpdated = DateTime.now();
          error = null;
          notifyListeners();
        },
        onConnection: (value) {
          connected = value;
          if (value) {
            error = null;
            _reconnectTimer?.cancel();
          }
          notifyListeners();
        },
        onError: (exception) {
          connected = false;
          error = _friendlyError(exception);
          notifyListeners();
          _scheduleReconnect();
        },
      );
    } catch (exception) {
      connected = false;
      error = _friendlyError(exception);
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_shuttingDown || config == null || _reconnectTimer?.isActive == true) {
      return;
    }
    _reconnectTimer = Timer(const Duration(seconds: 8), () async {
      if (_shuttingDown || config == null) {
        return;
      }
      try {
        await refresh();
        socket = HomeAssistantSocket(config!);
        await _connectSocket();
      } catch (exception) {
        error = _friendlyError(exception);
        notifyListeners();
        _reconnectTimer = null;
        _scheduleReconnect();
      }
    });
  }

  Future<void> refresh() async {
    if (api == null) {
      return;
    }
    final states = await api!.getStates();
    entities
      ..clear()
      ..addEntries(states.map((e) => MapEntry(e.entityId, e)));
    lastUpdated = DateTime.now();
    error = null;
    notifyListeners();
  }

  Future<void> logOut() async {
    _shuttingDown = true;
    _reconnectTimer?.cancel();
    await socket?.disconnect();
    api?.close();
    await _store.clear();
    config = null;
    api = null;
    socket = null;
    entities.clear();
    connected = false;
    error = null;
    lastUpdated = null;
    notifyListeners();
  }

  String _friendlyError(Object exception) {
    final message = exception.toString().replaceFirst('Exception: ', '');
    if (message.contains('SocketConnection failed') ||
        message.contains('Failed host lookup')) {
      return 'Home Assistant could not be reached. Check Wi-Fi, the address and port, then try again.';
    }
    if (message.contains('Connection refused')) {
      return 'The phone reached that address, but Home Assistant refused the connection. Check that Home Assistant is running and port 8123 is correct.';
    }
    if (message.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'The HTTPS certificate could not be verified. Use a valid certificate or connect using your trusted Home Assistant address.';
    }
    return message;
  }

  @override
  void dispose() {
    _shuttingDown = true;
    _reconnectTimer?.cancel();
    api?.close();
    unawaited(socket?.disconnect());
    super.dispose();
  }
}
