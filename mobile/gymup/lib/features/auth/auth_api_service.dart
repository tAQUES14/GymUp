import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_service.dart';

class AuthApiService {
  static String get baseUrl => ApiService.baseUrl;

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
      throw AuthApiException(
        data['message'] as String? ?? 'Erro ao fazer login',
        statusCode: response.statusCode,
        code: data['code'] as String?,
        email: data['email'] as String?,
      );
    }

    if (data['token'] != null) {
      await _saveSession(data);
    }
    return data;
  }

  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    String? inviteCode,
  }) async {
    final body = <String, dynamic>{'id_token': idToken};
    if (inviteCode != null && inviteCode.isNotEmpty) {
      body['invite_code'] = inviteCode.trim().toUpperCase();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 422) {
      final errors = data['errors'] as Map<String, dynamic>?;
      final firstMessage = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : (data['message'] as String? ?? 'Dados invalidos');
      throw Exception(firstMessage);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Erro ao entrar com Google');
    }

    if (data['needs_invite'] != true) {
      await _saveSession(data);
    }

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (inviteCode != null && inviteCode.isNotEmpty) {
      body['invite_code'] = inviteCode.trim().toUpperCase();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
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

    if (data['token'] != null) {
      await _saveSession(data);
    }
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    await _persistUser(data, prefs);

    return data;
  }

  /// Resolve um código de convite para o nome da academia.
  /// Retorna `{ 'id': int, 'name': String }` ou lança Exception se inválido.
  Future<Map<String, dynamic>> getGymByInvite(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gym/by-invite/${Uri.encodeComponent(code.trim().toUpperCase())}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 404) {
      throw Exception(data['message'] ?? 'Código inválido');
    }
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao verificar código');
    }

    return data;
  }

  /// Solicita o envio do link de recuperação de senha.
  /// Sempre retorna sem erro quando o servidor processa (200).
  Future<void> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao processar solicitação');
    }
  }

  /// Redefine a senha com o token recebido por e-mail.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'token':                 token,
        'email':                 email,
        'password':              password,
        'password_confirmation': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 422) {
      throw Exception(data['message'] ?? 'Token inválido ou expirado.');
    }
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao redefinir senha');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearUserCache(prefs, includeToken: true);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers internos
  // ──────────────────────────────────────────────────────────────────────────

  /// Salva token e user_id no SharedPreferences.
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return;

    await _clearUserCache(prefs, includeToken: false);
    await prefs.setString('auth_token', token);

    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      await _persistUser(user, prefs);
    }
  }

  Future<void> _persistUser(
    Map<String, dynamic> user,
    SharedPreferences prefs,
  ) async {
    final id = user['id'];
    if (id is num) {
      await prefs.setInt('user_id', id.toInt());
    }

    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    await prefs.setString('user_name', name);
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);

    final avatarUrl = user['avatar_url']?.toString() ?? '';
    if (avatarUrl.trim().isEmpty) {
      await prefs.remove('user_avatar_url');
    } else {
      await prefs.setString('user_avatar_url', avatarUrl);
    }

    final points = user['points_balance'];
    if (points is num) {
      await prefs.setInt('profile_points_balance', points.toInt());
    }

    final checkins = user['total_checkins'];
    if (checkins is num) {
      await prefs.setInt('profile_total_checkins', checkins.toInt());
    }

    final streak = user['current_streak'];
    if (streak is num) {
      await prefs.setInt('profile_current_streak', streak.toInt());
    }

    final chainId = user['gym_chain_id'];
    if (chainId is num) {
      await prefs.setInt('gym_chain_id', chainId.toInt());
    } else {
      await prefs.remove('gym_chain_id');
    }
  }

  Future<void> _clearUserCache(
    SharedPreferences prefs, {
    required bool includeToken,
  }) async {
    if (includeToken) {
      await prefs.remove('auth_token');
      await prefs.remove('token');
    }
    await prefs.remove('auth_user');
    await prefs.remove('user');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar_url');
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_points_balance');
    await prefs.remove('profile_total_checkins');
    await prefs.remove('profile_current_streak');
    await prefs.remove('gym_name');
    await prefs.remove('gym_chain_id');
  }

  Future<void> resendVerificationEmail({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/email/verification-notification'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao reenviar verificacao');
    }
  }
}

class AuthApiException implements Exception {
  const AuthApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.email,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? email;

  @override
  String toString() => message;
}
