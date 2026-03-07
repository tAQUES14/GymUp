import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';

class WorkoutExecutionService {
  final _api = ApiService();

  // ────────────────────────────────────────────────────────────────────────────
  // Weight: save per set
  // ────────────────────────────────────────────────────────────────────────────

  /// PUT /api/exercises/{exerciseId}/weight/set
  ///
  /// Sempre cria um novo registro (INSERT). Nunca sobrescreve.
  /// GUARD: exerciseId <= 0 → chamada bloqueada, nenhuma requisição HTTP é feita.
  Future<void> saveSetWeight({
    required int exerciseId,
    required int setNumber,
    required double weight,
    int reps = 0,
  }) async {
    if (exerciseId <= 0) {
      debugPrint(
        '[ExecService] saveSetWeight BLOQUEADO: exerciseId=$exerciseId é inválido (≤ 0).',
      );
      return;
    }

    final body = {'set_number': setNumber, 'weight': weight, 'reps': reps};

    debugPrint(
      '[ExecService] saveSetWeight HTTP PUT /exercises/$exerciseId/weight/set '
      'body=$body',
    );

    final response = await _api.put('/exercises/$exerciseId/weight/set', body);

    debugPrint(
      '[ExecService] saveSetWeight RESPONSE status=${response.statusCode} '
      'body=${response.body}',
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Falha ao salvar carga (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }
  // ────────────────────────────────────────────────────────────────────────────
  // Weight: load last per set
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/exercises/{exerciseId}/weight/last
  ///
  /// Retorna { set_number: weight } do último registro por série.
  /// GUARD: exerciseId <= 0 → retorna {} sem requisição HTTP.
  Future<Map<int, double>> loadExerciseWeights({
    required int exerciseId,
  }) async {
    if (exerciseId <= 0) {
      debugPrint(
        '[ExecService] loadExerciseWeights BLOQUEADO: exerciseId=$exerciseId é inválido (≤ 0).',
      );
      return {};
    }

    final response = await _api.get('/exercises/$exerciseId/weight/last');

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar cargas (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null || decoded is! Map) return {};

    // Backend retorna { "1": 50.0, "2": 55.0, ... }
    // Valores podem vir como num ou String dependendo do driver do BD.
    return decoded.map<int, double>(
      (key, value) => MapEntry(
        int.tryParse(key.toString()) ?? 0,
        (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0,
      ),
    );
  }
}
