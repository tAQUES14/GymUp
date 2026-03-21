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
  });

  bool get isCardio    => type == 'cardio';
  bool get isMobility  => type == 'mobility';
  bool get isStrength  => type == 'strength';

  bool get isSuperset  => technique == 'superset';
  bool get isDropset   => technique == 'dropset';
  bool get isCircuit   => technique == 'circuit';
  bool get isNormal    => technique == 'normal';

  factory WorkoutPlanExerciseModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

class WorkoutPlanDayModel {
  final int id;
  final int planId;
  final int dayOrder;
  final String name;
  final bool restDay;
  final List<WorkoutPlanExerciseModel> exercises;

  const WorkoutPlanDayModel({
    required this.id,
    required this.planId,
    required this.dayOrder,
    required this.name,
    required this.restDay,
    required this.exercises,
  });

  factory WorkoutPlanDayModel.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    return WorkoutPlanDayModel(
      id:        (json['id'] as num).toInt(),
      planId:    (json['plan_id'] as num).toInt(),
      dayOrder:  (json['day_order'] as num?)?.toInt() ?? 1,
      name:      json['name'] as String? ?? '',
      restDay:   json['rest_day'] as bool? ?? false,
      exercises: rawExercises
          .map((e) => WorkoutPlanExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Compact summary of a plan day used for the sequence strip.
/// Does not include exercises — only metadata for display.
class PlanDaySummary {
  final int    dayOrder;
  final String name;
  final bool   restDay;

  const PlanDaySummary({
    required this.dayOrder,
    required this.name,
    required this.restDay,
  });

  factory PlanDaySummary.fromJson(Map<String, dynamic> json) {
    return PlanDaySummary(
      dayOrder: (json['day_order'] as num?)?.toInt() ?? 1,
      name:     json['name'] as String? ?? '',
      restDay:  json['rest_day'] as bool? ?? false,
    );
  }
}

class TodayWorkoutPlan {
  final int planId;
  final String planName;
  final int currentDayIndex;
  final int totalDays;
  final int betweenExerciseRestSeconds;
  final WorkoutPlanDayModel currentDay;
  final List<PlanDaySummary> allDays;

  const TodayWorkoutPlan({
    required this.planId,
    required this.planName,
    required this.currentDayIndex,
    required this.totalDays,
    this.betweenExerciseRestSeconds = 180,
    required this.currentDay,
    this.allDays = const [],
  });

  bool get isRestDay => currentDay.restDay;

  factory TodayWorkoutPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['all_days'] as List<dynamic>? ?? [];
    return TodayWorkoutPlan(
      planId:                       (json['plan_id'] as num).toInt(),
      planName:                     json['plan_name'] as String? ?? '',
      currentDayIndex:              (json['current_day_index'] as num?)?.toInt() ?? 1,
      totalDays:                    (json['total_days'] as num?)?.toInt() ?? 1,
      betweenExerciseRestSeconds:   (json['between_exercise_rest_seconds'] as num?)?.toInt() ?? 180,
      currentDay:                   WorkoutPlanDayModel.fromJson(
                                      json['current_day'] as Map<String, dynamic>,
                                    ),
      allDays: rawDays
          .map((d) => PlanDaySummary.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
