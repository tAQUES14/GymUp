import 'dart:convert';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// IP do servidor de desenvolvimento para Android físico.
/// Emulador → troque por: 10.0.2.2
/// Dispositivo físico → IP da máquina na rede local
const _androidDevHost = '192.168.0.104';
const _productionBaseUrl = 'https://api.gymupapp.com.br/api';

class ApiService {
  /// URL base da API.
  ///
  /// No Android emulator, `localhost` aponta para o próprio dispositivo —
  /// o host é acessado via `10.0.2.2`. Em dispositivo físico, usar o IP
  /// da máquina na rede local (ver constante `_androidDevHost` acima).
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    const useProductionApi = bool.fromEnvironment('USE_PRODUCTION_API');
    if (useProductionApi) return _productionBaseUrl;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !kReleaseMode) {
      return 'http://$_androidDevHost:8000/api';
    }

    return _productionBaseUrl;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<http.Response> get(String endpoint) async {
    final token = await _getToken();

    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();

    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();

    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.StreamedResponse> multipartPost(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    return request.send();
  }
}
