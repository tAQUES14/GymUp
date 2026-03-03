import '../models/workout_model.dart';

/// Dados de treino offline para uso em telas de preview/demo (ex: WorkoutsPage).
///
/// IMPORTANTE: IDs negativos são INTENCIONAIS — sinalizam que estes objetos
/// não têm correspondente real no banco de dados.
/// NUNCA passe WorkoutsMock para o fluxo de execução real (WorkoutStepPage,
/// WorkoutExecutionPage) pois isso gera chamadas inválidas como
/// /api/exercises/-1/weight/last. Use sempre um WorkoutModel obtido do backend.
class WorkoutsMock {
  static final List<WorkoutModel> standardWorkouts = [
    WorkoutModel(
      id: -1,
      name: 'Treino A – Peito e Tríceps',
      description: 'Foco em empurrar e força superior.',
      duration: 45,
      level: 'Intermediário',
      exercises: [
        ExerciseModel(
          id: -1,
          name: 'Supino Reto',
          muscleGroup: 'Peito',
          defaultRest: 60,
          sets: 4,
          reps: 10,
          rest: 60,
        ),
        ExerciseModel(
          id: -2,
          name: 'Supino Inclinado com Halteres',
          muscleGroup: 'Peito',
          defaultRest: 60,
          sets: 4,
          reps: 10,
          rest: 60,
        ),
        ExerciseModel(
          id: -3,
          name: 'Tríceps Pulley',
          muscleGroup: 'Tríceps',
          defaultRest: 45,
          sets: 3,
          reps: 12,
          rest: 45,
        ),
      ],
    ),
    WorkoutModel(
      id: -2,
      name: 'Treino B – Costas e Bíceps',
      description: 'Foco em puxar e largura das costas.',
      duration: 50,
      level: 'Intermediário',
      exercises: [
        ExerciseModel(
          id: -4,
          name: 'Puxada Alta',
          muscleGroup: 'Costas',
          defaultRest: 60,
          sets: 4,
          reps: 10,
          rest: 60,
        ),
        ExerciseModel(
          id: -5,
          name: 'Remada Curvada',
          muscleGroup: 'Costas',
          defaultRest: 60,
          sets: 4,
          reps: 10,
          rest: 60,
        ),
        ExerciseModel(
          id: -6,
          name: 'Rosca Direta',
          muscleGroup: 'Bíceps',
          defaultRest: 45,
          sets: 3,
          reps: 12,
          rest: 45,
        ),
      ],
    ),
    WorkoutModel(
      id: -3,
      name: 'Treino C – Pernas',
      description: 'Treino completo de membros inferiores.',
      duration: 60,
      level: 'Avançado',
      exercises: [
        ExerciseModel(
          id: -7,
          name: 'Agachamento Livre',
          muscleGroup: 'Pernas',
          defaultRest: 90,
          sets: 4,
          reps: 8,
          rest: 90,
        ),
        ExerciseModel(
          id: -8,
          name: 'Leg Press 45',
          muscleGroup: 'Pernas',
          defaultRest: 60,
          sets: 4,
          reps: 10,
          rest: 60,
        ),
        ExerciseModel(
          id: -9,
          name: 'Cadeira Extensora',
          muscleGroup: 'Quadríceps',
          defaultRest: 45,
          sets: 3,
          reps: 15,
          rest: 45,
        ),
      ],
    ),
    WorkoutModel(
      id: -4,
      name: 'Full Body – Iniciante',
      description: 'Treino para o corpo todo, ideal para começar.',
      duration: 40,
      level: 'Iniciante',
      exercises: [
        ExerciseModel(
          id: -10,
          name: 'Agachamento (Peso do corpo)',
          muscleGroup: 'Pernas',
          defaultRest: 45,
          sets: 3,
          reps: 15,
          rest: 45,
        ),
        ExerciseModel(
          id: -11,
          name: 'Flexão de Braços',
          muscleGroup: 'Peito',
          defaultRest: 45,
          sets: 3,
          reps: 12,
          rest: 45,
        ),
        ExerciseModel(
          id: -12,
          name: 'Prancha Abdominal',
          muscleGroup: 'Core',
          defaultRest: 30,
          sets: 3,
          reps: 30,
          rest: 30,
        ),
      ],
    ),
  ];
}
