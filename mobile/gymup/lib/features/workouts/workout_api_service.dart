import 'dart:convert';
import '../../../core/api/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard DTOs
// ─────────────────────────────────────────────────────────────────────────────

class RecentActivity {
  final String type;
  final DateTime date;
  final int points;

  const RecentActivity({
    required this.type,
    required this.date,
    required this.points,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      points: (json['points'] as num).toInt(),
    );
  }
}

class DashboardData {
  final int pointsBalance;
  final bool hasCompletedToday;
  final bool hasActiveSession;
  final bool hasCheckedInToday;
  final List<bool> weeklyProgress;
  final List<RecentActivity> recentActivities;
  final int streak;

  const DashboardData({
    required this.pointsBalance,
    required this.hasCompletedToday,
    required this.hasActiveSession,
    required this.hasCheckedInToday,
    required this.weeklyProgress,
    required this.recentActivities,
    required this.streak,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pointsBalance: (json['points_balance'] as num).toInt(),
      hasCompletedToday: json['has_completed_today'] as bool? ?? false,
      hasActiveSession: json['has_active_session'] as bool? ?? false,
      hasCheckedInToday: json['has_checked_in_today'] as bool? ?? false,
      weeklyProgress: (json['weekly_progress'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      recentActivities: (json['recent_activities'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

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
  final bool meetsConditions;
  final int minMinutes;
  final int minProgress;
  final bool isBonusSession;
  final bool dailyPointsAlreadyGranted;

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
    required this.meetsConditions,
    required this.minMinutes,
    required this.minProgress,
    required this.isBonusSession,
    required this.dailyPointsAlreadyGranted,
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
      meetsConditions: json['meets_conditions'] as bool? ?? false,
      minMinutes: (json['min_minutes'] as num?)?.toInt() ?? 10,
      minProgress: (json['min_progress'] as num?)?.toInt() ?? 70,
      isBonusSession: json['is_bonus_session'] as bool? ?? false,
      dailyPointsAlreadyGranted:
          json['daily_points_already_granted'] as bool? ?? false,
    );
  }
}

class WorkoutApiService {
  final _api = ApiService();

  /// GET /api/dashboard
  ///
  /// Retorna os dados consolidados da home: pontos, progresso semanal,
  /// atividades recentes, e flags de estado (has_active_session, etc.).
  /// Lança [Exception('401')] se não autenticado.
  Future<DashboardData> getDashboard() async {
    final response = await _api.get('/dashboard');

    if (response.statusCode == 401) throw Exception('401');

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar dashboard.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DashboardData.fromJson(body);
  }

  /// POST /api/workout/start
  ///
  /// Inicia uma nova sessão de treino ou retorna a sessão ativa existente.
  /// Nunca lança exceção para sessão duplicada — o backend é idempotente.
  /// Lança [Exception('401')] se não autenticado.
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
    final response = await _api.post('/workout/progress', {
      'progress': progress,
    });
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

    // 409 is treated as success — backend returns the existing session.
    // 200 = existing session returned, 201 = new session created.
    if (statusCode != 200 && statusCode != 201 && statusCode != 409) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro na sessão de treino.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>?;
    if (session == null || session['id'] == null) {
      throw Exception('Sessão inválida retornada pelo servidor.');
    }
    return WorkoutSessionData.fromJson(session);
  }
}
