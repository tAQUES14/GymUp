import 'dart:convert';
import '../../../core/api/api_service.dart';

class CheckinApiService {
  final _api = ApiService();

  /// Registra o check-in do dia.
  ///
  /// Retorna `true` se o check-in foi realizado agora, `false` se já havia
  /// sido feito hoje (409 → idempotente, não é erro).
  ///
  /// Lança:
  /// - [Exception('401')] → token expirado
  /// - [Exception(mensagem)] → qualquer outro erro da API
  Future<bool> doCheckIn() async {
    final response = await _api.post('/checkin', {});

    if (response.statusCode == 401) throw Exception('401');

    // 409 = check-in já realizado hoje → idempotente, não é erro.
    if (response.statusCode == 409) return false;

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao realizar check-in.');
    }

    return true;
  }
}
