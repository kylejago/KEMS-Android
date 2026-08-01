import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_config.dart';

class SecureConfigStore {
  static const _urlKey = 'ha_base_url';
  static const _tokenKey = 'ha_access_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AppConfig?> read() async {
    final url = await _storage.read(key: _urlKey);
    final token = await _storage.read(key: _tokenKey);
    if (url == null || token == null || url.isEmpty || token.isEmpty) return null;
    return AppConfig(baseUrl: url, token: token);
  }

  Future<void> write(AppConfig config) async {
    await _storage.write(key: _urlKey, value: config.normalizedBaseUrl);
    await _storage.write(key: _tokenKey, value: config.token.trim());
  }

  Future<void> clear() => _storage.deleteAll();
}
