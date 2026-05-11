import 'dart:convert';
import '../../../core/api/api_service.dart';
import 'redemption_model.dart';
import 'reward_model.dart';

class RewardApiService {
  final _api = ApiService();

  Future<List<Reward>> getRewards() async {
    final response = await _api.get('/rewards');

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar recompensas.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((json) => Reward.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> redeemReward(int rewardId) async {
    final response = await _api.post('/redeem', {'reward_id': rewardId});

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao resgatar recompensa.');
    }
  }

  Future<List<Redemption>> getMyRedemptions() async {
    final response = await _api.get('/user/redemptions?per_page=50');

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar resgates.');
    }

    final body = jsonDecode(response.body);
    final List<dynamic> items =
        body is List ? body : (body['data'] as List<dynamic>? ?? []);

    return items
        .map((e) => Redemption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
