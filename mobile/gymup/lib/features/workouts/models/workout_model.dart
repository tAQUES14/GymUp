class WorkoutSet {
  final int number;
  double weight;
  int reps;
  bool isCompleted;

  WorkoutSet({
    required this.number,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      number: map['number'] ?? 1,
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class ExerciseModel {
  final int id;
  final String name;
  final String muscleGroup;
  final int defaultRest;
  final int sets;
  final int reps;
  final int rest;
  double carga;
  List<WorkoutSet> workoutSets;

  /// True once the user has completed all sets of this exercise.
  /// Marked one-way: once true it stays true regardless of later unchecks,
  /// so revisiting an exercise does not inflate the progress counter.
  bool isCompleted;

  /// Convenience: checks whether every set in workoutSets is marked done.
  bool get allSetsCompleted => workoutSets.every((s) => s.isCompleted);

  ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.defaultRest,
    required this.sets,
    required this.reps,
    required this.rest,
    this.carga = 0.0,
    this.isCompleted = false,
    List<WorkoutSet>? workoutSets,
  }) : workoutSets = workoutSets ??
            List.generate(
              sets,
              (i) => WorkoutSet(number: i + 1, weight: 0.0, reps: reps),
            );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'default_rest': defaultRest,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'carga': carga,
      'isCompleted': isCompleted,
      'workoutSets': workoutSets.map((x) => x.toMap()).toList(),
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    final pivot = map['pivot'] as Map<String, dynamic>? ?? {};
    final setsCount = (pivot['sets'] ?? 3) as int;
    final repsCount = (pivot['reps'] ?? 12) as int;
    final restSeconds = (pivot['rest'] ?? map['default_rest'] ?? 60) as int;

    List<WorkoutSet> workoutSets;
    if (map['workoutSets'] != null) {
      workoutSets = List<WorkoutSet>.from(
        (map['workoutSets'] as List<dynamic>).map(
          (x) => WorkoutSet.fromMap(x as Map<String, dynamic>),
        ),
      );
    } else {
      workoutSets = List.generate(
        setsCount,
        (i) => WorkoutSet(number: i + 1, weight: 0.0, reps: repsCount),
      );
    }

    return ExerciseModel(
      id: map['id'] as int,
      name: map['name'] ?? '',
      muscleGroup: map['muscle_group'] ?? '',
      defaultRest: (map['default_rest'] ?? 60) as int,
      sets: setsCount,
      reps: repsCount,
      rest: restSeconds,
      carga: (map['carga'] ?? 0).toDouble(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      workoutSets: workoutSets,
    );
  }
}

class WorkoutModel {
  final int id;
  final String name;
  final String description;
  final int? duration;
  final String? level;
  final List<ExerciseModel> exercises;
  final bool isGenerated;

  WorkoutModel({
    required this.id,
    required this.name,
    required this.description,
    this.duration,
    this.level,
    required this.exercises,
    this.isGenerated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'level': level,
      'exercises': exercises.map((x) => x.toMap()).toList(),
      'is_generated': isGenerated,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as int,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] as int?,
      level: map['level'] as String?,
      exercises: List<ExerciseModel>.from(
        (map['exercises'] as List<dynamic>? ?? []).map(
          (x) => ExerciseModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      isGenerated: map['is_generated'] ?? false,
    );
  }
}
