import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao fazer login');
    }

    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 422) {
      // Erros de validação: pega a primeira mensagem disponível.
      final errors = data['errors'] as Map<String, dynamic>?;
      final firstMessage = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : (data['message'] as String? ?? 'Dados inválidos');
      throw Exception(firstMessage);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Erro ao criar conta');
    }

    await _saveSession(data);
    return data;
  }

  /// Busca o usuário autenticado enviando o Bearer token salvo.
  /// Lança [Exception('401')] se o token estiver expirado ou inválido.
  Future<Map<String, dynamic>> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('401');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await logout();
      throw Exception('401');
    }

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao buscar usuário');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers internos
  // ──────────────────────────────────────────────────────────────────────────

  /// Salva token e user_id no SharedPreferences.
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token'] as String);

    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      await prefs.setInt('user_id', (user['id'] as num).toInt());
    }
  }
}
