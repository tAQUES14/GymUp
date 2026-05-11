import 'models/workout_model.dart';
import 'models/workout_plan_model.dart';

/// Converte um [TodayWorkoutPlan] (do endpoint /workout-plan/today)
/// em um [WorkoutModel] compatível com a tela de execução de treino.
///
/// Usado por [HomePage], [WorkoutsPage] e [CheckinPage] para evitar
/// duplicação da mesma lógica de conversão.
WorkoutModel workoutFromPlan(TodayWorkoutPlan plan) {
  final exercises = plan.today.exercises.map((pe) {
    int parsedReps = 10;
    if (pe.isCardio) {
      parsedReps = pe.durationMinutes ?? 10;
    } else if (pe.reps != null) {
      final repsStr = pe.reps!.replaceAll(RegExp(r'[^0-9]'), '');
      if (repsStr.isNotEmpty) parsedReps = int.tryParse(repsStr) ?? 10;
    }
    return ExerciseModel(
      id:               pe.exerciseId,
      name:             pe.name,
      muscleGroup:      pe.muscleGroup,
      gifUrl:           pe.gifUrl,
      defaultRest:      pe.defaultRest,
      sets:             pe.sets ?? 1,
      reps:             parsedReps,
      rest:             pe.isCardio ? 0 : pe.restSeconds,
      description:      pe.description,
      primaryMuscle:    pe.primaryMuscle,
      secondaryMuscles: pe.secondaryMuscles,
      executionSteps:   pe.executionSteps,
      commonMistakes:   pe.commonMistakes,
      tips:             pe.tips,
    );
  }).toList();

  return WorkoutModel(
    id:                         plan.today.id ?? plan.today.dayOfWeek,
    name:                       plan.today.name,
    description:                plan.planName,
    exercises:                  exercises,
    betweenExerciseRestSeconds: plan.betweenExerciseRestSeconds,
  );
}
