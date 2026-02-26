import 'dart:convert';
import '../../../core/api/api_service.dart';

/// Snapshot de uma sessão de treino retornada pelo backend.
class WorkoutSessionData {
  final int id;
  final String startedAt;
  final String? finishedAt;
  final bool isActive;
  final int progress;
  final int elapsedSeconds;
  final bool pointsGranted;
  final String? pointsGrantedAt;
  final bool canEarnPoints;

  const WorkoutSessionData({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.isActive,
    required this.progress,
    required this.elapsedSeconds,
    required this.pointsGranted,
    this.pointsGrantedAt,
    required this.canEarnPoints,
  });

  factory WorkoutSessionData.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionData(
      id: (json['id'] as num).toInt(),
      startedAt: json['started_at'] as String,
      finishedAt: json['finished_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      pointsGranted: json['points_granted'] as bool? ?? false,
      pointsGrantedAt: json['points_granted_at'] as String?,
      canEarnPoints: json['can_earn_points'] as bool? ?? false,
    );
  }
}

class WorkoutApiService {
  final _api = ApiService();

  /// POST /api/workout/start
  ///
  /// Inicia uma nova sessão de treino.
  /// Lança [Exception('401')] se não autenticado.
  /// Lança [Exception('409')] se já existe sessão ativa.
  Future<WorkoutSessionData> startWorkout() async {
    final response = await _api.post('/workout/start', {});
    return _parseSession(response.statusCode, response.body);
  }

  /// GET /api/workout/status
  ///
  /// Retorna a sessão mais recente ou null se não houver nenhuma.
  /// Lança [Exception('401')] se não autenticado.
  Future<WorkoutSessionData?> getStatus() async {
    final response = await _api.get('/workout/status');

    if (response.statusCode == 401) throw Exception('401');

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao obter status do treino.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final session = body['session'];
    if (session == null) return null;

    return WorkoutSessionData.fromJson(session as Map<String, dynamic>);
  }

  /// POST /api/workout/progress { progress: 0-100 }
  ///
  /// Atualiza o progresso da sessão ativa.
  /// O backend concede pontos automaticamente quando as condições forem
  /// atingidas (tempo mínimo + progress >= 70%).
  /// Lança [Exception('401')] ou [Exception('404')] conforme o backend.
  Future<WorkoutSessionData> updateProgress(int progress) async {
    final response = await _api.post('/workout/progress', {'progress': progress});
    return _parseSession(response.statusCode, response.body);
  }

  /// POST /api/workout/finish
  ///
  /// Finaliza a sessão ativa. Se as condições forem atendidas e os pontos
  /// ainda não foram concedidos, o backend os concede agora.
  /// Lança [Exception('401')] ou [Exception('404')] conforme o backend.
  Future<WorkoutSessionData> finishWorkout() async {
    final response = await _api.post('/workout/finish', {});
    return _parseSession(response.statusCode, response.body);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  WorkoutSessionData _parseSession(int statusCode, String body) {
    if (statusCode == 401) throw Exception('401');
    if (statusCode == 404) throw Exception('404');
    if (statusCode == 409) throw Exception('409');

    if (statusCode != 200 && statusCode != 201) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro na sessão de treino.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return WorkoutSessionData.fromJson(
      data['session'] as Map<String, dynamic>,
    );
  }
}
