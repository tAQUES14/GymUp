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

class DashboardData {
  final String name;
  final int pointsBalance;
  final bool hasCompletedToday;
  final bool hasActiveSession;
  final bool hasCheckedInToday;
  final List<bool> weeklyProgress;
  final List<RecentActivity> recentActivities;
  final int streak;
  final int bestStreak;
  final List<int> trainingDays;
  final int weeklyGoal;
  final int remainingWorkoutsThisWeek;
  final int totalCheckins;
  final int totalWorkouts;
  final int totalWorkoutsWithPoints;

  const DashboardData({
    required this.name,
    required this.pointsBalance,
    required this.hasCompletedToday,
    required this.hasActiveSession,
    required this.hasCheckedInToday,
    required this.weeklyProgress,
    required this.recentActivities,
    required this.streak,
    required this.bestStreak,
    required this.trainingDays,
    required this.weeklyGoal,
    required this.remainingWorkoutsThisWeek,
    required this.totalCheckins,
    required this.totalWorkouts,
    required this.totalWorkoutsWithPoints,
  });

  int get totalWorkoutsWithoutPoints => totalWorkouts - totalWorkoutsWithPoints;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      name: json['name'] as String? ?? '',
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
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      trainingDays: (json['training_days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      weeklyGoal: (json['weekly_goal'] as num?)?.toInt() ?? 3,
      remainingWorkoutsThisWeek:
          (json['remaining_workouts_this_week'] as num?)?.toInt() ?? 0,
      totalCheckins: (json['total_checkins'] as num?)?.toInt() ?? 0,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalWorkoutsWithPoints:
          (json['total_workouts_with_points'] as num?)?.toInt() ?? 0,
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
      minProgress:
          (requirements['min_progress_valid'] as num?)?.toInt() ?? 75,
      dailyPointsAlreadyGranted:
          json['daily_points_already_granted'] as bool? ?? false,
      isValid: json['is_valid'] as bool? ?? false,
      countsForPoints: json['counts_for_points'] as bool? ?? false,
      countsForStreak: json['counts_for_streak'] as bool? ?? false,
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

/// Resultado do POST /workout/finish — fonte de verdade para pontos e streak.
class WorkoutFinishResult {
  /// VALID | PARTIAL_CONFIRM | INVALID
  final String status;
  final String message;
  final int pointsGenerated;
  final int streakCurrent;
  final int bestStreak;

  /// True quando este treino incrementou o streak diário.
  final bool streakJustIncreased;

  final int totalPoints;
  final bool checkinValidated;

  /// True quando este treino foi o que completou a meta semanal pela primeira
  /// vez nesta semana. Usado para exibir o modal comemorativo (uma vez/semana).
  final bool weeklyGoalJustCompleted;

  final int remainingWorkoutsThisWeek;
  final WorkoutSessionData session;

  /// Dados do desafio ativo após o treino. Null se não houver desafio.
  final Map<String, dynamic>? challengeProgress;

  /// Motivational progress message generated by the backend when the user
  /// improved their performance vs the previous session (e.g. "+2kg no Supino").
  /// Null when no improvement was detected or no sets were recorded.
  final String? progressMessage;

  /// List of PR achievement messages (e.g. "🔥 Novo recorde de carga: 65kg no Supino").
  final List<String> prMessages;

  /// Total volume (sum of weight × reps) across all sets in this session.
  final int workoutVolume;

  const WorkoutFinishResult({
    required this.status,
    required this.message,
    required this.pointsGenerated,
    required this.streakCurrent,
    required this.bestStreak,
    required this.streakJustIncreased,
    required this.totalPoints,
    required this.checkinValidated,
    required this.weeklyGoalJustCompleted,
    required this.remainingWorkoutsThisWeek,
    required this.session,
    this.challengeProgress,
    this.progressMessage,
    this.prMessages = const [],
    this.workoutVolume = 0,
  });

  bool get isValid => status == 'VALID';
  bool get isPartialConfirm => status == 'PARTIAL_CONFIRM';
  bool get isInvalid => status == 'INVALID';

  factory WorkoutFinishResult.fromJson(Map<String, dynamic> json) {
    return WorkoutFinishResult(
      status: json['status'] as String? ?? 'INVALID',
      message: json['message'] as String? ?? '',
      pointsGenerated: (json['points_generated'] as num?)?.toInt() ?? 0,
      streakCurrent: (json['streak_current'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      streakJustIncreased: json['streak_just_increased'] as bool? ?? false,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      checkinValidated: json['checkin_validated'] as bool? ?? false,
      weeklyGoalJustCompleted:
          json['weekly_goal_just_completed'] as bool? ?? false,
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
  ///
  /// Envia completion_percent, duration_seconds e confirm_partial.
  /// Retorna [WorkoutFinishResult] com status, message, points_generated,
  /// streak_current, total_points — a fonte de verdade.
  Future<WorkoutFinishResult> finishWorkout({
    required int completionPercent,
    required int durationSeconds,
    bool confirmPartial = false,
  }) async {
    final response = await _api.post('/workout/finish', {
      'completion_percent': completionPercent,
      'duration_seconds': durationSeconds,
      'confirm_partial': confirmPartial,
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
  ///
  /// Returns the enriched last-sets snapshot: sets, max_weight, volume,
  /// estimated_1rm, workout_date. Returns null when no history exists.
  Future<ExerciseLastSets?> getLastSets(int exerciseId) async {
    final response = await _api.get('/exercises/$exerciseId/last-sets');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = ExerciseLastSets.fromJson(data);
    return result.hasData ? result : null;
  }

  /// GET /api/exercises/prs
  ///
  /// Returns all-time PRs for every exercise the user has trained.
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
  ///
  /// Returns last 20 sessions containing this exercise, ordered chronologically,
  /// with per-session metrics (max_weight, volume, estimated_1rm).
  Future<List<ExerciseHistoryPoint>> getExerciseWorkoutHistory(
      int exerciseId) async {
    final response =
        await _api.get('/exercises/$exerciseId/workout-history');
    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['history'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            ExerciseHistoryPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/workout-sets
  ///
  /// Saves all sets for one exercise within a session. Idempotent — replaces
  /// any previously saved sets for the same exercise+session.
  Future<void> saveWorkoutSets({
    required int sessionId,
    required int exerciseId,
    required List<Map<String, dynamic>> sets,
  }) async {
    final response = await _api.post('/workout-sets', {
      'workout_session_id': sessionId,
      'exercise_id': exerciseId,
      'sets': sets,
    });
    if (response.statusCode == 401) throw Exception('401');
    // Non-critical: silently ignore other errors
  }

  /// GET /api/exercises/{id}/substitutions
  ///
  /// Returns list of substitute exercises (id, name, muscle_group, type, image_url).
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

    final data = jsonDecode(body) as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>?;
    if (session == null || session['id'] == null) {
      throw Exception('Sessão inválida retornada pelo servidor.');
    }
    return WorkoutSessionData.fromJson(session);
  }
}
