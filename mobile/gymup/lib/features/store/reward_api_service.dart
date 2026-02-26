import 'dart:convert';
import '../../../core/api/api_service.dart';
import 'reward_model.dart';

class RewardApiService {
  final _api = ApiService();

  /// Retorna as recompensas ativas da academia do usuário autenticado.
  /// Lança [Exception('401')] se o token estiver expirado.
  Future<List<Reward>> getRewards() async {
    final response = await _api.get('/rewards');

    if (response.statusCode == 401) {
      throw Exception('401');
    }
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar recompensas.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((json) => Reward.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Cria uma solicitação de resgate PENDENTE para [rewardId].
  /// Lança [Exception] com a mensagem do servidor em caso de erro.
  /// Casos tratados: 401 (sessão expirada), 422 (pontos insuficientes),
  /// 400 (sem estoque), 409 (já existe solicitação pendente).
  Future<void> redeemReward(int rewardId) async {
    final response = await _api.post('/redeem', {'reward_id': rewardId});

    if (response.statusCode == 401) {
      throw Exception('401');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao resgatar recompensa.');
    }
  }
}
