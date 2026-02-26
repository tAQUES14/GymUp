import 'dart:convert';
import '../../../core/api/api_service.dart';

class CheckinApiService {
  final _api = ApiService();

  /// Registra o check-in do dia e retorna o novo saldo de pontos.
  ///
  /// Lança:
  /// - [Exception('401')] → token expirado
  /// - [Exception('409')] → check-in já feito hoje
  /// - [Exception(mensagem)] → qualquer outro erro da API
  Future<int> doCheckIn() async {
    final response = await _api.post('/checkin', {});

    if (response.statusCode == 401) {
      throw Exception('401');
    }

    if (response.statusCode == 409) {
      throw Exception('409');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao realizar check-in.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['points_balance'] as num?)?.toInt() ?? 0;
  }
}
