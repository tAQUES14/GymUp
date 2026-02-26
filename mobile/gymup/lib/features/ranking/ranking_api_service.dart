import 'dart:convert';
import '../../../core/api/api_service.dart';

class RankingItem {
  final int position;
  final int userId;
  final String name;
  final int points;
  final int streak;

  const RankingItem({
    required this.position,
    required this.userId,
    required this.name,
    required this.points,
    required this.streak,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      position: (json['position'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String,
      points: (json['points'] as num).toInt(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class RankingApiService {
  final _api = ApiService();

  /// Busca o ranking do período informado.
  ///
  /// [period] deve ser: 'weekly', 'monthly', 'quarterly' ou 'all'.
  ///
  /// Lança:
  /// - [Exception('401')] → token expirado
  /// - [Exception(mensagem)] → qualquer outro erro da API
  Future<List<RankingItem>> getRanking({String period = 'all'}) async {
    final response = await _api.get('/ranking?period=$period');

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
