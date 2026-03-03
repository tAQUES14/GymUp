import 'dart:convert';
import '../../../core/api/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DTOs
// ─────────────────────────────────────────────────────────────────────────────

class WeightHistoryEntry {
  final int setNumber;
  final double weight;
  final int reps;
  final DateTime createdAt;

  const WeightHistoryEntry({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.createdAt,
  });

  factory WeightHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WeightHistoryEntry(
      setNumber: (json['set_number'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ProgressPoint {
  final String weekStartDate;
  final double value;

  const ProgressPoint({required this.weekStartDate, required this.value});

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      weekStartDate: json['week_start_date'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
}

class PersonalRecord {
  final double? bestWeight;
  final int? bestReps;
  final double? bestE1rm;
  final String? createdAt;

  const PersonalRecord({
    this.bestWeight,
    this.bestReps,
    this.bestE1rm,
    this.createdAt,
  });

  bool get isEmpty => bestE1rm == null;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      bestWeight: (json['best_weight'] as num?)?.toDouble(),
      bestReps: (json['best_reps'] as num?)?.toInt(),
      bestE1rm: (json['best_e1rm'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class ProgressScore {
  final double? current;
  final double? past;
  final double? deltaAbs;
  final double? deltaPct;

  const ProgressScore({this.current, this.past, this.deltaAbs, this.deltaPct});

  bool get hasData => current != null && past != null;

  factory ProgressScore.fromJson(Map<String, dynamic> json) {
    return ProgressScore(
      current: (json['current'] as num?)?.toDouble(),
      past: (json['past'] as num?)?.toDouble(),
      deltaAbs: (json['delta_abs'] as num?)?.toDouble(),
      deltaPct: (json['delta_pct'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseStatsService {
  static final ExerciseStatsService _instance = ExerciseStatsService._internal();
  factory ExerciseStatsService() => _instance;
  ExerciseStatsService._internal();

  final _api = ApiService();

  // Cache leve em memória: chave = "endpoint:exerciseId:params"
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheDuration = Duration(minutes: 5);

  /// GET /api/exercises/{exerciseId}/history
  Future<List<WeightHistoryEntry>> getHistory(
    int exerciseId, {
    int? setNumber,
    int limit = 50,
  }) async {
    final key = 'history:$exerciseId:${setNumber ?? "all"}:$limit';
    final cached = _getFromCache<List<WeightHistoryEntry>>(key);
    if (cached != null) return cached;

    var endpoint = '/exercises/$exerciseId/history?limit=$limit';
    if (setNumber != null) endpoint += '&set_number=$setNumber';

    final response = await _api.get(endpoint);
    _assertOk(response.statusCode, response.body);

    final list = (jsonDecode(response.body) as List<dynamic>)
        .map((e) => WeightHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    _putInCache(key, list);
    return list;
  }

  /// GET /api/exercises/{exerciseId}/progress
  Future<List<ProgressPoint>> getProgress(
    int exerciseId, {
    int setNumber = 1,
    int weeks = 12,
  }) async {
    final key = 'progress:$exerciseId:$setNumber:$weeks';
    final cached = _getFromCache<List<ProgressPoint>>(key);
    if (cached != null) return cached;

    final endpoint =
        '/exercises/$exerciseId/progress?set_number=$setNumber&weeks=$weeks';

    final response = await _api.get(endpoint);
    _assertOk(response.statusCode, response.body);

    final list = (jsonDecode(response.body) as List<dynamic>)
        .map((e) => ProgressPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    _putInCache(key, list);
    return list;
  }

  /// GET /api/exercises/{exerciseId}/pr
  Future<PersonalRecord> getPR(int exerciseId) async {
    final key = 'pr:$exerciseId';
    final cached = _getFromCache<PersonalRecord>(key);
    if (cached != null) return cached;

    final response = await _api.get('/exercises/$exerciseId/pr');
    _assertOk(response.statusCode, response.body);

    final pr = PersonalRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _putInCache(key, pr);
    return pr;
  }

  /// GET /api/exercises/{exerciseId}/progress-score
  Future<ProgressScore> getProgressScore(
    int exerciseId, {
    int setNumber = 1,
    int days = 30,
  }) async {
    final key = 'score:$exerciseId:$setNumber:$days';
    final cached = _getFromCache<ProgressScore>(key);
    if (cached != null) return cached;

    final endpoint =
        '/exercises/$exerciseId/progress-score?set_number=$setNumber&days=$days';

    final response = await _api.get(endpoint);
    _assertOk(response.statusCode, response.body);

    final score = ProgressScore.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _putInCache(key, score);
    return score;
  }

  /// Limpa cache para um exercício (ex: após salvar novo peso).
  void invalidate(int exerciseId) {
    _cache.removeWhere((key, _) => key.contains(':$exerciseId:') || key.endsWith(':$exerciseId'));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cache helpers
  // ──────────────────────────────────────────────────────────────────────────

  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.createdAt) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void _putInCache(String key, dynamic data) {
    _cache[key] = _CacheEntry(data: data, createdAt: DateTime.now());
  }

  void _assertOk(int statusCode, String body) {
    if (statusCode == 401) throw Exception('401');
    if (statusCode >= 400) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Erro ao carregar dados.');
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime createdAt;

  _CacheEntry({required this.data, required this.createdAt});
}
