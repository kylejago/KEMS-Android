class AppConfig {
  const AppConfig({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  String get normalizedBaseUrl => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
}
