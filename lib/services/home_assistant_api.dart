import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_config.dart';
import '../models/ha_entity.dart';

class HomeAssistantConnectionException implements Exception {
  const HomeAssistantConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeAssistantApi {
  HomeAssistantApi(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final AppConfig config;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${config.token}',
        'Content-Type': 'application/json',
      };

  Future<void> validateConnection() async {
    final response = await _request(
      () => _client.get(
        Uri.parse('${config.normalizedBaseUrl}/api/'),
        headers: _headers,
      ),
      timeout: const Duration(seconds: 12),
    );

    switch (response.statusCode) {
      case 200:
        return;
      case 401:
        throw const HomeAssistantConnectionException(
          'Home Assistant rejected the access token. Create a new Long-Lived Access Token in your Home Assistant profile.',
        );
      case 404:
        throw const HomeAssistantConnectionException(
          'Home Assistant was reached, but its API was not found. Check the address and port.',
        );
      default:
        throw HomeAssistantConnectionException(
          'Home Assistant returned HTTP ${response.statusCode}.',
        );
    }
  }

  Future<List<HaEntity>> getStates() async {
    final response = await _request(
      () => _client.get(
        Uri.parse('${config.normalizedBaseUrl}/api/states'),
        headers: _headers,
      ),
      timeout: const Duration(seconds: 20),
    );
    if (response.statusCode == 401) {
      throw const HomeAssistantConnectionException(
        'Home Assistant authentication expired or was revoked.',
      );
    }
    if (response.statusCode != 200) {
      throw HomeAssistantConnectionException(
        'Home Assistant returned HTTP ${response.statusCode} while loading entities.',
      );
    }
    return (jsonDecode(response.body) as List)
        .map((item) => HaEntity.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> callService(
    String domain,
    String service,
    Map<String, dynamic> data,
  ) async {
    final response = await _request(
      () => _client.post(
        Uri.parse('${config.normalizedBaseUrl}/api/services/$domain/$service'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeAssistantConnectionException(
        'Service call failed with HTTP ${response.statusCode}.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
    String entityId, {
    Duration period = const Duration(hours: 24),
  }) async {
    final start = DateTime.now().toUtc().subtract(period).toIso8601String();
    final uri = Uri.parse('${config.normalizedBaseUrl}/api/history/period/$start')
        .replace(queryParameters: {
      'filter_entity_id': entityId,
      'minimal_response': '1',
      'no_attributes': '1',
    });
    final response = await _request(
      () => _client.get(uri, headers: _headers),
      timeout: const Duration(seconds: 20),
    );
    if (response.statusCode != 200) {
      return const [];
    }
    final decoded = jsonDecode(response.body) as List;
    if (decoded.isEmpty) {
      return const [];
    }
    return List<Map<String, dynamic>>.from(
      (decoded.first as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() operation, {
    required Duration timeout,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      throw const HomeAssistantConnectionException(
        'Connection timed out. Check that this phone is on the same network as Home Assistant.',
      );
    } on SocketException catch (error) {
      final detail = error.osError?.message.toLowerCase() ?? '';
      if (detail.contains('operation not permitted')) {
        throw const HomeAssistantConnectionException(
          'Android blocked network access for this build. Install the latest KEMS Companion APK, which includes the required Internet permission.',
        );
      }
      throw const HomeAssistantConnectionException(
        'Home Assistant could not be reached. Check the address, Wi-Fi connection, and whether port 8123 is accessible.',
      );
    } on http.ClientException {
      throw const HomeAssistantConnectionException(
        'Home Assistant could not be reached. Check the address, Wi-Fi connection, and whether HTTP or HTTPS is correct.',
      );
    } on FormatException {
      throw const HomeAssistantConnectionException(
        'The server returned an unexpected response. Check that the address points to Home Assistant.',
      );
    }
  }

  void close() => _client.close();
}
