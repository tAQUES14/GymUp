import 'dart:convert';
import '../../../core/api/api_service.dart';
import 'models/workout_model.dart';

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
      date: DateTime.parse(json['date'] as String).toLocal(),
      points: (json['points'] as num).toInt(),
    );
  }
}

/// Progresso de um dia da semana retornado pelo dashboard.
///
/// day_of_week: 0=Domingo, 1=Segunda, ..., 6=Sábado
class WeeklyProgressDay {
  final int dayOfWeek;
  final bool isPlanDay;
  final bool isRestDay;
  final bool gymOpen;
  final bool isObligatory;
  final bool trained;
  final bool trainedOnPlan;

  const WeeklyProgressDay({
    required this.dayOfWeek,
    required this.isPlanDay,
    required this.isRestDay,
    required this.gymOpen,
    required this.isObligatory,
    required this.trained,
    required this.trainedOnPlan,
  });

  factory WeeklyProgressDay.fromJson(Map<String, dynamic> json) {
    return WeeklyProgressDay(
      dayOfWeek:     (json['day_of_week'] as num).toInt(),
      isPlanDay:     json['is_plan_day']    == true,
      isRestDay:     json['is_rest_day']    != false,
      gymOpen:       json['gym_open']       != false,
      isObligatory:  json['is_obligatory']  == true,
      trained:       json['trained']        == true,
      trainedOnPlan: json['trained_on_plan'] == true,
    );
  }
}

class DashboardData {
  final String name;
  final int pointsBalance;
  final bool hasCompletedToday;
  final bool hasActiveSession;
  final int? activeSessionElapsedMinutes;
  final bool hasCheckedInToday;
  /// Lista de 7 dias (0=Dom → 6=Sáb) com contexto completo.
  final List<WeeklyProgressDay> weeklyProgress;
  final List<RecentActivity> recentActivities;
  final int streak;
  final int bestStreak;
  final int weeklyGoal;
  final int remainingWorkoutsThisWeek;
  final int workoutsDoneThisWeek;
  final int totalCheckins;
  final int totalWorkouts;
  final int totalWorkoutsWithPoints;
  /// Posição no ranking da academia. 0 = sem dados.
  final int ranking;

  const DashboardData({
    required this.name,
    required this.pointsBalance,
    required this.hasCompletedToday,
    required this.hasActiveSession,
    this.activeSessionElapsedMinutes,
    required this.hasCheckedInToday,
    required this.weeklyProgress,
    required this.recentActivities,
    required this.streak,
    required this.bestStreak,
    required this.weeklyGoal,
    required this.remainingWorkoutsThisWeek,
    required this.workoutsDoneThisWeek,
    required this.totalCheckins,
    required this.totalWorkouts,
    required this.totalWorkoutsWithPoints,
    this.ranking = 0,
  });

  int get totalWorkoutsWithoutPoints => totalWorkouts - totalWorkoutsWithPoints;

  /// Quantidade de treinos com pontos na semana atual.
  int get onPlanWorkoutsDone => workoutsDoneThisWeek;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['weekly_progress'] as List<dynamic>? ?? [];
    return DashboardData(
      name:             json['name'] as String? ?? '',
      pointsBalance:    (json['points_balance'] as num).toInt(),
      hasCompletedToday:    json['has_completed_today']  == true,
      hasActiveSession:     json['has_active_session']   == true,
      activeSessionElapsedMinutes: (json['active_session_elapsed_minutes'] as num?)?.toInt(),
      hasCheckedInToday:    json['has_checked_in_today'] == true,
      weeklyProgress: rawProgress
          .map((e) => WeeklyProgressDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivities: (json['recent_activities'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      streak:               (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak:           (json['best_streak'] as num?)?.toInt() ?? 0,
      weeklyGoal:           (json['weekly_goal'] as num?)?.toInt() ?? 3,
      remainingWorkoutsThisWeek:
          (json['remaining_workouts_this_week'] as num?)?.toInt() ?? 0,
      workoutsDoneThisWeek:
          (json['workouts_done_this_week'] as num?)?.toInt() ?? 0,
      totalCheckins:    (json['total_checkins'] as num?)?.toInt() ?? 0,
      totalWorkouts:    (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalWorkoutsWithPoints:
          (json['total_workouts_with_points'] as num?)?.toInt() ?? 0,
      ranking: (json['ranking'] as num?)?.toInt() ?? 0,
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
  final bool dailyPointsAlreadyGranted;
  final bool isValid;
  final bool countsForPoints;
  /// true = sessão foi on-plan (contou para streak e meta semanal)
  final bool countsForStreak;

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
    required this.dailyPointsAlreadyGranted,
    required this.isValid,
    required this.countsForPoints,
    required this.countsForStreak,
  });

  factory WorkoutSessionData.fromJson(Map<String, dynamic> json) {
    final requirements = json['requirements'] as Map<String, dynamic>? ?? {};
    return WorkoutSessionData(
      id:           (json['id'] as num).toInt(),
      startedAt:    json['started_at'] as String,
      finishedAt:   json['finished_at'] as String?,
      isActive:     json['is_active'] != false,
      progress:     (json['progress'] as num?)?.toInt() ?? 0,
      elapsedSeconds:     (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      pointsGranted:      json['points_granted']    == true,
      pointsGrantedAt:    json['points_granted_at'] as String?,
      canEarnPoints:      json['can_earn_points']   == true,
      meetsConditions:    json['meets_conditions']  == true,
      minMinutes:         (json['min_minutes'] as num?)?.toInt() ?? 10,
      minProgress:        (requirements['min_progress_valid'] as num?)?.toInt() ?? 75,
      dailyPointsAlreadyGranted: json['daily_points_already_granted'] == true,
      isValid:            json['is_valid']         == true,
      countsForPoints:    json['counts_for_points'] == true,
      countsForStreak:    json['counts_for_streak'] == true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise progression DTOs
// ─────────────────────────────────────────────────────────────────────────────

/// Enriched snapshot of the last time the user performed an exercise.
class ExerciseLastSets {
  final int exerciseId;
  final String? workoutDate;
  final List<Map<String, dynamic>> sets;
  final double? maxWeight;
  final double? volume;
  final double? estimated1RM;

  const ExerciseLastSets({
    required this.exerciseId,
    this.workoutDate,
    required this.sets,
    this.maxWeight,
    this.volume,
    this.estimated1RM,
  });

  bool get hasData => sets.isNotEmpty;

  factory ExerciseLastSets.fromJson(Map<String, dynamic> json) {
    return ExerciseLastSets(
      exerciseId:  (json['exercise_id'] as num).toInt(),
      workoutDate: json['workout_date'] as String?,
      sets: List<Map<String, dynamic>>.from(
        (json['sets'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      maxWeight:   (json['max_weight'] as num?)?.toDouble(),
      volume:      (json['volume'] as num?)?.toDouble(),
      estimated1RM:(json['estimated_1rm'] as num?)?.toDouble(),
    );
  }
}

/// One data-point in an exercise's session-based progression history.
class ExerciseHistoryPoint {
  final String date;
  final double maxWeight;
  final double volume;
  final double estimated1RM;

  const ExerciseHistoryPoint({
    required this.date,
    required this.maxWeight,
    required this.volume,
    required this.estimated1RM,
  });

  factory ExerciseHistoryPoint.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryPoint(
      date:         json['date'] as String,
      maxWeight:    (json['max_weight'] as num).toDouble(),
      volume:       (json['volume'] as num).toDouble(),
      estimated1RM: (json['estimated_1rm'] as num).toDouble(),
    );
  }
}

/// All-time PR record for a single exercise.
class ExercisePRRecord {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final double maxWeight;
  final double? maxEstimated1RM;

  const ExercisePRRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.maxWeight,
    this.maxEstimated1RM,
  });

  factory ExercisePRRecord.fromJson(Map<String, dynamic> json) {
    return ExercisePRRecord(
      exerciseId:      (json['exercise_id'] as num).toInt(),
      exerciseName:    json['exercise_name'] as String,
      muscleGroup:     json['muscle_group'] as String? ?? '',
      maxWeight:       (json['max_weight'] as num).toDouble(),
      maxEstimated1RM: (json['max_estimated_1rm'] as num?)?.toDouble(),
    );
  }
}

/// Resultado do POST /workout/finish.
class WorkoutFinishResult {
  final String status;
  final String message;
  final int pointsGenerated;
  /// true se o treino foi feito em um dia do plano (on-plan).
  final bool isOnPlan;
  final int streakCurrent;
  final int bestStreak;
  final bool streakJustIncreased;
  final int totalPoints;
  final bool checkinValidated;
  final int remainingWorkoutsThisWeek;
  final WorkoutSessionData session;
  final Map<String, dynamic>? challengeProgress;
  final String? progressMessage;
  final List<String> prMessages;
  final int workoutVolume;

  const WorkoutFinishResult({
    required this.status,
    required this.message,
    required this.pointsGenerated,
    required this.isOnPlan,
    required this.streakCurrent,
    required this.bestStreak,
    required this.streakJustIncreased,
    required this.totalPoints,
    required this.checkinValidated,
    required this.remainingWorkoutsThisWeek,
    required this.session,
    this.challengeProgress,
    this.progressMessage,
    this.prMessages = const [],
    this.workoutVolume = 0,
  });

  /// Mantido por compatibilidade — backend não envia mais este campo.
  bool get weeklyGoalJustCompleted => false;

  bool get isValid => status == 'VALID';
  bool get isPartialConfirm => status == 'PARTIAL_CONFIRM';
  bool get isInvalid => status == 'INVALID';

  factory WorkoutFinishResult.fromJson(Map<String, dynamic> json) {
    return WorkoutFinishResult(
      status:           json['status'] as String? ?? 'INVALID',
      message:          json['message'] as String? ?? '',
      pointsGenerated:  (json['points_generated'] as num?)?.toInt() ?? 0,
      isOnPlan:         json['is_on_plan']          == true,
      streakCurrent:    (json['streak_current'] as num?)?.toInt() ?? 0,
      bestStreak:       (json['best_streak'] as num?)?.toInt() ?? 0,
      streakJustIncreased:    json['streak_just_increased'] == true,
      totalPoints:            (json['total_points'] as num?)?.toInt() ?? 0,
      checkinValidated:       json['checkin_validated'] == true,
      remainingWorkoutsThisWeek:
          (json['remaining_workouts_this_week'] as num?)?.toInt() ?? 0,
      session: WorkoutSessionData.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      challengeProgress: json['challenge_progress'] as Map<String, dynamic>?,
      progressMessage:   json['progress_message'] as String?,
      prMessages: (json['pr_messages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      workoutVolume: (json['workout_volume'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkoutApiService {
  final _api = ApiService();

  /// GET /api/custom-workouts
  Future<List<WorkoutModel>> getWorkouts() async {
    final response = await _api.get('/custom-workouts');

    if (response.statusCode == 401) throw Exception('401');

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar treinos.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => WorkoutModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/dashboard
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
  Future<WorkoutSessionData> startWorkout() async {
    final response = await _api.post('/workout/start', {});
    return _parseSession(response.statusCode, response.body);
  }

  /// GET /api/workout/status
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
  Future<WorkoutSessionData> updateProgress(int progress) async {
    final response = await _api.post('/workout/progress', {
      'progress': progress,
    });
    return _parseSession(response.statusCode, response.body);
  }

  /// POST /api/workout/finish
  Future<WorkoutFinishResult> finishWorkout({
    required int completionPercent,
    required int durationSeconds,
    bool confirmPartial = false,
  }) async {
    final response = await _api.post('/workout/finish', {
      'completion_percent': completionPercent,
      'duration_seconds':   durationSeconds,
      'confirm_partial':    confirmPartial,
    });

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode == 404) throw Exception('404');

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao finalizar treino.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WorkoutFinishResult.fromJson(data);
  }

  /// GET /api/exercises/{id}/last-sets
  Future<ExerciseLastSets?> getLastSets(int exerciseId) async {
    final response = await _api.get('/exercises/$exerciseId/last-sets');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = ExerciseLastSets.fromJson(data);
    return result.hasData ? result : null;
  }

  /// GET /api/exercises/prs
  Future<List<ExercisePRRecord>> getAllPRs() async {
    final response = await _api.get('/exercises/prs');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['prs'] as List<dynamic>? ?? [];
    return list
        .map((e) => ExercisePRRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/exercises/{id}/workout-history
  Future<List<ExerciseHistoryPoint>> getExerciseWorkoutHistory(
      int exerciseId) async {
    final response =
        await _api.get('/exercises/$exerciseId/workout-history');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['history'] as List<dynamic>? ?? [];
    return list
        .map((e) => ExerciseHistoryPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/workout-sets
  Future<void> saveWorkoutSets({
    required int sessionId,
    required int exerciseId,
    required List<Map<String, dynamic>> sets,
  }) async {
    final response = await _api.post('/workout-sets', {
      'workout_session_id': sessionId,
      'exercise_id':        exerciseId,
      'sets':               sets,
    });
    if (response.statusCode == 401) throw Exception('401');
  }

  /// GET /api/exercises/{id}/substitutions
  Future<List<Map<String, dynamic>>> getSubstitutions(int exerciseId) async {
    final response = await _api.get('/exercises/$exerciseId/substitutions');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['substitutions'] as List? ?? []);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  WorkoutSessionData _parseSession(int statusCode, String body) {
    if (statusCode == 401) throw Exception('401');
    if (statusCode == 404) throw Exception('404');

    if (statusCode != 200 && statusCode != 201 && statusCode != 409) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro na sessão de treino.');
    }

    final data    = jsonDecode(body) as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>?;
    if (session == null || session['id'] == null) {
      throw Exception('Sessão inválida retornada pelo servidor.');
    }
    return WorkoutSessionData.fromJson(session);
  }
}
