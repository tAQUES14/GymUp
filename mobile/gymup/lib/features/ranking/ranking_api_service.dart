import 'dart:convert';
import '../../../core/api/api_service.dart';

class RankingItem {
  final int position;
  final int userId;
  final String name;
  final int points;
  final int streak;
  /// Percentual de crescimento em relação à semana anterior.
  /// Não nulo apenas quando period=progress.
  /// 999 significa crescimento infinito (sem pontos na semana anterior).
  final int? growthPct;
  /// Nome da academia — presente apenas quando scope=chain.
  final String? gymName;

  const RankingItem({
    required this.position,
    required this.userId,
    required this.name,
    required this.points,
    required this.streak,
    this.growthPct,
    this.gymName,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      position:  (json['position'] as num).toInt(),
      userId:    (json['user_id'] as num).toInt(),
      name:      json['name'] as String,
      points:    (json['points'] as num).toInt(),
      streak:    (json['streak'] as num?)?.toInt() ?? 0,
      growthPct: (json['growth_pct'] as num?)?.toInt(),
      gymName:   json['gym_name'] as String?,
    );
  }
}

class RankingApiService {
  final _api = ApiService();

  /// Busca o ranking do período e escopo informados.
  ///
  /// [period]: 'all', 'weekly', 'monthly', 'quarterly', 'progress'.
  /// [scope]: 'gym' (apenas a academia do usuário) ou 'chain' (toda a rede).
  Future<List<RankingItem>> getRanking({
    String period = 'all',
    String scope  = 'gym',
  }) async {
    final response = await _api.get('/ranking?period=$period&scope=$scope');

    if (response.statusCode == 401) {
      throw Exception('401');
    }

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar ranking.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => RankingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
