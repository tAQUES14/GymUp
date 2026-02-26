import 'dart:convert';
import '../../../core/api/api_service.dart';

class DashboardApiService {
  final _api = ApiService();

  /// Busca o dashboard do usuário autenticado.
  ///
  /// Retorna mapa com:
  ///   points_balance      : int
  ///   has_checked_in_today: bool
  ///   streak              : int
  ///   total_checkins      : int
  ///
  /// Lança [Exception('401')] se o token estiver expirado.
  /// Lança [Exception(mensagem)] para qualquer outro erro da API.
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _api.get('/dashboard');

    if (response.statusCode == 401) {
      throw Exception('401');
    }

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar dashboard.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
