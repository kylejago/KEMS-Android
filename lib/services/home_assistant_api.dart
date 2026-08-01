import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_config.dart';
import '../models/ha_entity.dart';

class HomeAssistantApi {
  HomeAssistantApi(this.config);
  final AppConfig config;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${config.token}',
        'Content-Type': 'application/json',
      };

  Future<bool> ping() async {
    final response = await http
        .get(Uri.parse('${config.normalizedBaseUrl}/api/'), headers: _headers)
        .timeout(const Duration(seconds: 12));
    return response.statusCode == 200;
  }

  Future<List<HaEntity>> getStates() async {
    final response = await http
        .get(Uri.parse('${config.normalizedBaseUrl}/api/states'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Home Assistant returned ${response.statusCode}.');
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
    final response = await http
        .post(
          Uri.parse('${config.normalizedBaseUrl}/api/services/$domain/$service'),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Service call failed (${response.statusCode}).');
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
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return const [];
    final decoded = jsonDecode(response.body) as List;
    if (decoded.isEmpty) return const [];
    return List<Map<String, dynamic>>.from(
      (decoded.first as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }
}
