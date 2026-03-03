import 'package:flutter/foundation.dart';

/// Cache simples de estatísticas por exercício.
///
/// Usado pelo [WorkoutExecutionController] para invalidar dados em cache
/// após salvar um novo peso, garantindo que a próxima consulta
/// busque dados atualizados do backend.
class ExerciseStatsService {
  static final ExerciseStatsService _instance = ExerciseStatsService._();
  factory ExerciseStatsService() => _instance;
  ExerciseStatsService._();

  final Set<int> _invalidated = {};

  /// Marca o exercício como invalidado (cache sujo).
  void invalidate(int exerciseId) {
    _invalidated.add(exerciseId);
    debugPrint('[ExerciseStatsService] invalidate exerciseId=$exerciseId');
  }

  /// Retorna true se o exercício foi invalidado desde a última limpeza.
  bool isInvalidated(int exerciseId) => _invalidated.contains(exerciseId);

  /// Limpa a flag de invalidação após recarregar os dados.
  void clearInvalidation(int exerciseId) {
    _invalidated.remove(exerciseId);
  }
}
