import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';
import '../services/exercise_stats_service.dart';
import '../../services/workout_execution_service.dart';
import '../workout_api_service.dart';

/// Central state for a workout execution session.
///
/// Holds all per-set weights and completion flags so they survive
/// navigation, rebuilds, and exercise switching.
class WorkoutExecutionController extends ChangeNotifier {
  final WorkoutModel workout;
  final WorkoutExecutionService _service;

  // exerciseId → setNumber → weight
  final Map<int, Map<int, double>> _weights = {};

  // exerciseId → set of completed setNumbers
  final Map<int, Set<int>> _completedSets = {};

  // One-way lock: once an exercise is fully done, it stays done
  final Set<int> _completedExerciseIds = {};

  // Debounce timers: key = "$exerciseId-$setNumber"
  final Map<String, Timer> _saveTimers = {};

  bool isLoadingWeights = false;

  /// Mensagem de erro do último save, ou null se tudo ok.
  /// A UI deve observar via listener e mostrar feedback ao usuário.
  String? saveError;

  WorkoutExecutionController({required this.workout})
      : _service = WorkoutExecutionService() {
    debugPrint(
      '[Controller] CRIADO para workout=${workout.id} "${workout.name}" '
      '(hashCode=$hashCode)',
    );

    final invalidExercises = workout.exercises.where((e) => e.id <= 0).toList();
    if (invalidExercises.isNotEmpty) {
      debugPrint(
        '[Controller] ATENÇÃO: ${invalidExercises.length} exercício(s) com ID inválido (≤ 0). '
        'Use workouts carregados do backend, não de WorkoutsMock.',
      );
    }
  }

  @override
  void dispose() {
    debugPrint('[Controller] DISPOSE workout=${workout.id} (hashCode=$hashCode)');
    for (final t in _saveTimers.values) {
      t.cancel();
    }
    _saveTimers.clear();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Weight access
  // ──────────────────────────────────────────────

  double getWeight(int exerciseId, int setNumber) =>
      _weights[exerciseId]?[setNumber] ?? 0.0;

  /// Atualiza o mapa local e dispara o salvamento no backend em fire-and-forget.
  /// Em caso de erro, define [saveError] e notifica listeners para exibição na UI.
  void setWeight(int exerciseId, int setNumber, double weight, {int reps = 0}) {
    if (exerciseId <= 0) {
      debugPrint(
        '[Controller] setWeight BLOQUEADO: exerciseId=$exerciseId é inválido (≤ 0).',
      );
      return;
    }

    _weights.putIfAbsent(exerciseId, () => {})[setNumber] = weight;

    debugPrint(
      '[Controller] setWeight exerciseId=$exerciseId '
      'setNumber=$setNumber weight=$weight  '
      'map agora=${_weights[exerciseId]}',
    );

    notifyListeners();

    // Debounce: cancel any pending save for this slot and restart the timer.
    // The API call only fires 800 ms after the user stops typing.
    final key = '$exerciseId-$setNumber';
    _saveTimers[key]?.cancel();
    _saveTimers[key] = Timer(const Duration(milliseconds: 800), () {
      _saveTimers.remove(key);
      _service
          .saveSetWeight(
            exerciseId: exerciseId,
            setNumber: setNumber,
            weight: weight,
            reps: reps,
          )
          .then((_) {
        ExerciseStatsService().invalidate(exerciseId);
        if (saveError != null) {
          saveError = null;
          notifyListeners();
        }
      }).catchError((e) {
        saveError = 'Erro ao salvar carga. Verifique sua conexão.';
        debugPrint('[Controller] saveSetWeight ERRO: $e');
        notifyListeners();
      });
    });
  }

  /// Chamado pela UI após exibir o erro para evitar re-exibição.
  void clearSaveError() {
    if (saveError != null) {
      saveError = null;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Set / exercise completion
  // ──────────────────────────────────────────────

  bool isSetCompleted(int exerciseId, int setNumber) =>
      _completedSets[exerciseId]?.contains(setNumber) ?? false;

  void markSetCompleted(int exerciseId, int setNumber, bool completed) {
    final sets = _completedSets.putIfAbsent(exerciseId, () => {});
    if (completed) {
      sets.add(setNumber);
    } else {
      sets.remove(setNumber);
    }

    debugPrint(
      '[Controller] markSetCompleted exerciseId=$exerciseId '
      'setNumber=$setNumber completed=$completed  '
      'concluídas=$sets',
    );

    // One-way exercise lock
    if (!_completedExerciseIds.contains(exerciseId)) {
      final exercise = workout.exercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => workout.exercises.first,
      );
      if (exercise.workoutSets.every((s) => sets.contains(s.number))) {
        _completedExerciseIds.add(exerciseId);
        debugPrint('[Controller] exercício $exerciseId CONCLUÍDO');
      }
    }

    notifyListeners();
  }

  bool isExerciseCompleted(int exerciseId) =>
      _completedExerciseIds.contains(exerciseId);

  // ──────────────────────────────────────────────
  // Progress
  // ──────────────────────────────────────────────

  double get progress {
    final total = workout.exercises.length;
    if (total == 0) return 0.0;
    return _completedExerciseIds.length / total;
  }

  int get completedExercisesCount => _completedExerciseIds.length;

  // ──────────────────────────────────────────────
  // Backend: load weights
  // ──────────────────────────────────────────────

  /// Carrega os pesos salvos para cada exercício do workout em paralelo.
  ///
  /// ESTRATÉGIA DE MERGE: dados do backend preenchem entradas ausentes,
  /// mas valores já definidos localmente (pelo usuário digitando) NUNCA
  /// são sobrescritos.
  Future<void> loadAllWeights() async {
    debugPrint(
      '[Controller] loadAllWeights INÍCIO '
      '(hashCode=$hashCode workout=${workout.id})',
    );
    isLoadingWeights = true;
    notifyListeners();

    await Future.wait(
      workout.exercises.map((exercise) async {
        if (exercise.id <= 0) {
          _weights.putIfAbsent(exercise.id, () => {});
          return;
        }

        try {
          final weights = await _service.loadExerciseWeights(
            exerciseId: exercise.id,
          );

          // Merge: backend preenche entradas ausentes; valores locais vencem.
          final existing = Map<int, double>.from(
            _weights[exercise.id] ?? {},
          );
          _weights[exercise.id] = {...weights, ...existing};

          debugPrint(
            '[Controller] loadAllWeights exercício=${exercise.id} '
            'backend=$weights  local=$existing  '
            'resultado=${_weights[exercise.id]}',
          );
        } catch (e) {
          debugPrint(
            '[Controller] loadAllWeights exercício=${exercise.id} ERRO: $e',
          );
          _weights.putIfAbsent(exercise.id, () => {});
        }
      }),
    );

    debugPrint(
      '[Controller] loadAllWeights CONCLUÍDO. _weights=$_weights',
    );
    isLoadingWeights = false;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Backend: finish workout
  // ──────────────────────────────────────────────

  final WorkoutApiService _apiService = WorkoutApiService();

  Future<WorkoutFinishResult> finishWorkout({
    required int durationMinutes,
    required int exercisesCompleted,
    required int exercisesTotal,
    bool confirmPartial = false,
  }) {
    final completionPercent = exercisesTotal > 0
        ? ((exercisesCompleted / exercisesTotal) * 100).round()
        : 0;

    return _apiService.finishWorkout(
      completionPercent: completionPercent,
      durationSeconds: durationMinutes * 60,
      confirmPartial: confirmPartial,
    );
  }
}
