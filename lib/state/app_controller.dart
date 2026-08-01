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

  bool get configured => config != null;
  HaEntity? entity(String id) => entities[id];
  List<HaEntity> get kemsEntities => entities.values
      .where((e) => e.entityId.startsWith('sensor.kems_') || e.entityId.startsWith('binary_sensor.kems_'))
      .toList()..sort((a, b) => a.entityId.compareTo(b.entityId));

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
    try {
      final candidateApi = HomeAssistantApi(candidate);
      if (!await candidateApi.ping()) throw Exception('Connection was rejected.');
      await _store.write(candidate);
      config = candidate;
      await _startConnection();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _startConnection() async {
    final current = config;
    if (current == null) return;
    api = HomeAssistantApi(current);
    socket = HomeAssistantSocket(current);
    try {
      final states = await api!.getStates();
      entities
        ..clear()
        ..addEntries(states.map((e) => MapEntry(e.entityId, e)));
      await socket!.connect(
        onStateChanged: (entity) {
          entities[entity.entityId] = entity;
          notifyListeners();
        },
        onConnection: (value) {
          connected = value;
          notifyListeners();
        },
        onError: (e) {
          error = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> refresh() async {
    if (api == null) return;
    final states = await api!.getStates();
    entities
      ..clear()
      ..addEntries(states.map((e) => MapEntry(e.entityId, e)));
    notifyListeners();
  }

  Future<void> logOut() async {
    await socket?.disconnect();
    await _store.clear();
    config = null;
    api = null;
    socket = null;
    entities.clear();
    connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(socket?.disconnect());
    super.dispose();
  }
}
