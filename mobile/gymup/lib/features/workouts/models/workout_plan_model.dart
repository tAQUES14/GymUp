/// Exercício dentro de um dia do plano.
class WorkoutPlanExerciseModel {
  final int id;
  final int exerciseId;
  final String name;
  final String muscleGroup;
  final String? imageUrl;
  final String? gifUrl;
  final String? videoUrl;
  /// 'strength' | 'cardio' | 'mobility'
  final String type;
  final int? sets;
  final String? reps;
  final int restSeconds;
  final int? durationMinutes;
  final double? distanceKm;
  /// 'normal' | 'superset' | 'dropset' | 'circuit'
  final String technique;
  final int? groupId;
  final int? rounds;
  final int? drops;
  final int exerciseOrder;
  final int defaultRest;
  final String? description;
  final String? primaryMuscle;
  final List<String> secondaryMuscles;
  final List<String> executionSteps;
  final List<String> commonMistakes;
  final List<String> tips;

  const WorkoutPlanExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.imageUrl,
    this.gifUrl,
    this.videoUrl,
    required this.type,
    this.sets,
    this.reps,
    required this.restSeconds,
    this.durationMinutes,
    this.distanceKm,
    this.technique = 'normal',
    this.groupId,
    this.rounds,
    this.drops,
    required this.exerciseOrder,
    required this.defaultRest,
    this.description,
    this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.executionSteps = const [],
    this.commonMistakes = const [],
    this.tips = const [],
  });

  bool get isCardio    => type == 'cardio';
  bool get isMobility  => type == 'mobility';
  bool get isStrength  => type == 'strength';

  bool get isSuperset  => technique == 'superset';
  bool get isDropset   => technique == 'dropset';
  bool get isCircuit   => technique == 'circuit';
  bool get isNormal    => technique == 'normal';

  factory WorkoutPlanExerciseModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return WorkoutPlanExerciseModel(
      id:              (json['id'] as num).toInt(),
      exerciseId:      (json['exercise_id'] as num).toInt(),
      name:            json['name'] as String? ?? '',
      muscleGroup:     json['muscle_group'] as String? ?? '',
      imageUrl:        json['image_url'] as String?,
      gifUrl:          json['gif_url'] as String?,
      videoUrl:        json['video_url'] as String?,
      type:            json['type'] as String? ?? 'strength',
      sets:            (json['sets'] as num?)?.toInt(),
      reps:            json['reps'] as String?,
      restSeconds:     (json['rest_seconds'] as num?)?.toInt() ?? 60,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      distanceKm:      (json['distance_km'] as num?)?.toDouble(),
      technique:       json['technique'] as String? ?? 'normal',
      groupId:         (json['group_id'] as num?)?.toInt(),
      rounds:          (json['rounds'] as num?)?.toInt(),
      drops:           (json['drops'] as num?)?.toInt(),
      exerciseOrder:   (json['exercise_order'] as num?)?.toInt() ?? 1,
      defaultRest:     (json['default_rest'] as num?)?.toInt() ?? 60,
      description:     json['description'] as String?,
      primaryMuscle:   json['primary_muscle'] as String?,
      secondaryMuscles: strList(json['secondary_muscles']),
      executionSteps:  strList(json['execution_steps']),
      commonMistakes:  strList(json['common_mistakes']),
      tips:            strList(json['tips']),
    );
  }
}

/// Dia do plano de treino (baseado em calendário).
class WorkoutPlanDayModel {
  final int? id;
  final int? planId;
  /// 0=Domingo, 1=Segunda, ..., 6=Sábado
  final int dayOfWeek;
  final String name;
  final bool restDay;
  final List<WorkoutPlanExerciseModel> exercises;

  const WorkoutPlanDayModel({
    this.id,
    this.planId,
    required this.dayOfWeek,
    required this.name,
    required this.restDay,
    required this.exercises,
  });

  factory WorkoutPlanDayModel.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    return WorkoutPlanDayModel(
      id:          (json['id'] as num?)?.toInt(),
      planId:      (json['plan_id'] as num?)?.toInt(),
      dayOfWeek:   (json['day_of_week'] as num?)?.toInt() ?? DateTime.now().weekday % 7,
      name:        json['name'] as String? ?? '',
      restDay:     json['rest_day'] == true,
      exercises:   rawExercises
          .map((e) => WorkoutPlanExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Resumo de um dia da semana no plano (para o overview semanal).
class WeekDaySummary {
  /// 0=Domingo, 1=Segunda, ..., 6=Sábado
  final int dayOfWeek;
  final bool hasWorkout;
  final bool restDay;
  final String name;

  const WeekDaySummary({
    required this.dayOfWeek,
    required this.hasWorkout,
    required this.restDay,
    required this.name,
  });

  factory WeekDaySummary.fromJson(Map<String, dynamic> json) {
    return WeekDaySummary(
      dayOfWeek:  (json['day_of_week'] as num).toInt(),
      hasWorkout: json['has_workout'] == true,
      restDay:    json['rest_day']   != false,
      name:       json['name'] as String? ?? 'Descanso',
    );
  }
}

/// Plano de treino do dia atual.
class TodayWorkoutPlan {
  final int planId;
  final String planName;
  final int betweenExerciseRestSeconds;
  /// Treino/descanso de hoje (day_of_week = hoje).
  final WorkoutPlanDayModel today;
  /// Resumo dos 7 dias da semana (0=Dom → 6=Sáb), keyed por day_of_week.
  final Map<int, WeekDaySummary> weekOverview;

  const TodayWorkoutPlan({
    required this.planId,
    required this.planName,
    this.betweenExerciseRestSeconds = 180,
    required this.today,
    this.weekOverview = const {},
  });

  bool get isRestDay => today.restDay;

  factory TodayWorkoutPlan.fromJson(Map<String, dynamic> json) {
    // week_overview pode vir como lista ou como mapa keyed por string
    final rawOverview = json['week_overview'];
    final Map<int, WeekDaySummary> overview = {};

    if (rawOverview is Map) {
      rawOverview.forEach((key, value) {
        final dow = int.tryParse(key.toString()) ?? 0;
        overview[dow] = WeekDaySummary.fromJson(value as Map<String, dynamic>);
      });
    } else if (rawOverview is List) {
      for (final item in rawOverview) {
        final s = WeekDaySummary.fromJson(item as Map<String, dynamic>);
        overview[s.dayOfWeek] = s;
      }
    }

    return TodayWorkoutPlan(
      planId:                       (json['plan_id'] as num).toInt(),
      planName:                     json['plan_name'] as String? ?? '',
      betweenExerciseRestSeconds:   (json['between_exercise_rest_seconds'] as num?)?.toInt() ?? 180,
      today:                        WorkoutPlanDayModel.fromJson(
                                      json['today'] as Map<String, dynamic>,
                                    ),
      weekOverview: overview,
    );
  }
}
