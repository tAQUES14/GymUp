import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_service.dart';

/// Serviço de autenticação acessível via Provider.
///
/// Usa a mesma chave `"auth_token"` que [ApiService] e [AuthApiService]
/// para que a sessão persista corretamente entre cold starts.
class AuthService {
  // Chave canônica do token — deve ser idêntica à usada por ApiService e AuthApiService.
  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'auth_user';

  String get baseUrl => ApiService.baseUrl;

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      return data['user'] as Map<String, dynamic>;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'phone': ?phone,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      return data['user'] as Map<String, dynamic>;
    } else {
      throw Exception('Register failed');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // Remove também chaves legadas para não deixar estado inconsistente
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey)
        ?? prefs.getString('user'); // fallback chave legada
    if (userString != null) {
      return jsonDecode(userString) as Map<String, dynamic>;
    }
    return null;
  }
}