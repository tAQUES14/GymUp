import 'dart:convert';
import '../../../core/api/api_service.dart';

class GoalData {
  final String goalType;
  final String gender;
  final double startWeight;
  final double targetWeight;
  final double height;
  final int age;
  final String activityLevel;
  final int targetMonths;
  final int? estimatedDailyCalorieDeficit;
  final int estimatedWorkoutsPerWeek;
  final DateTime createdAt;

  const GoalData({
    required this.goalType,
    required this.gender,
    required this.startWeight,
    required this.targetWeight,
    required this.height,
    required this.age,
    required this.activityLevel,
    required this.targetMonths,
    required this.estimatedDailyCalorieDeficit,
    required this.estimatedWorkoutsPerWeek,
    required this.createdAt,
  });

  factory GoalData.fromJson(Map<String, dynamic> json) {
    return GoalData(
      goalType: json['goal_type'] as String,
      gender: json['gender'] as String,
      startWeight: (json['start_weight'] as num).toDouble(),
      targetWeight: (json['target_weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      age: (json['age'] as num).toInt(),
      activityLevel: json['activity_level'] as String,
      targetMonths: (json['target_months'] as num).toInt(),
      estimatedDailyCalorieDeficit:
          (json['estimated_daily_calorie_deficit'] as num?)?.toInt(),
      estimatedWorkoutsPerWeek:
          (json['estimated_workouts_per_week'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  /// Reconstrói o payload de request a partir dos dados do GoalData.
  /// Usado para salvar uma meta que foi apenas previamente calculada.
  Map<String, dynamic> toRequestMap() => {
        'goal_type'      : goalType,
        'gender'         : gender,
        'start_weight'   : startWeight.toInt(),
        'target_weight'  : targetWeight.toInt(),
        'height'         : height.toInt(),
        'age'            : age,
        'activity_level' : activityLevel,
        'target_months'  : targetMonths,
      };

  String get goalTypeLabel {
    switch (goalType) {
      case 'weight_loss':
        return 'Perda de Peso';
      case 'weight_gain':
        return 'Ganho de Peso';
      case 'consistency':
        return 'Consistência';
      default:
        return goalType;
    }
  }

  String get activityLevelLabel {
    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentário';
      case 'light':
        return 'Leve';
      case 'moderate':
        return 'Moderado';
      case 'intense':
        return 'Intenso';
      default:
        return activityLevel;
    }
  }

  String get genderLabel => gender == 'male' ? 'Masculino' : 'Feminino';
}

class BodyWeightLog {
  final double weight;
  final DateTime recordedAt;

  const BodyWeightLog({required this.weight, required this.recordedAt});

  factory BodyWeightLog.fromJson(Map<String, dynamic> json) => BodyWeightLog(
        weight: (json['weight'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}

class GoalApiService {
  final _api = ApiService();

  /// Calcula estimativas sem salvar. Usado para preview antes de confirmar.
  Future<GoalData> previewGoal(Map<String, dynamic> data) async {
    final response = await _api.post('/goals/preview', data);

    if (response.statusCode == 200) {
      return GoalData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw _parseError(response, 'Erro ao calcular estimativa.');
  }

  /// Persiste a meta ativa do usuário (substitui a anterior se existir).
  Future<GoalData> createGoal(Map<String, dynamic> data) async {
    final response = await _api.post('/goals', data);

    if (response.statusCode == 201) {
      return GoalData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw _parseError(response, 'Erro ao salvar meta.');
  }

  /// Registra (ou atualiza) o peso corporal do dia.
  Future<BodyWeightLog> logBodyWeight(double weight) async {
    final response = await _api.post('/body-weight', {'weight': weight});

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BodyWeightLog.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw _parseError(response, 'Erro ao registrar peso.');
  }

  /// Retorna o histórico de pesos corporais (mais recente primeiro).
  Future<List<BodyWeightLog>> getBodyWeightHistory({int limit = 30}) async {
    final response = await _api.get('/body-weight?limit=$limit');

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => BodyWeightLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Erro ao buscar histórico de peso.');
  }

  Future<GoalData?> getCurrentGoal() async {
    final response = await _api.get('/goals/current');

    if (response.statusCode == 200) {
      return GoalData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 404) return null;

    throw Exception('Erro ao buscar meta.');
  }

  /// Extrai a mensagem de erro mais útil da resposta HTTP.
  Exception _parseError(dynamic response, String fallback) {
    if (response.statusCode == 401) {
      return Exception('Sessão expirada. Faça login novamente.');
    }
    try {
      final body = jsonDecode(response.body as String) as Map<String, dynamic>;
      if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final msg = errors.values
              .expand((v) => (v as List).cast<String>())
              .join(' ');
          return Exception(msg);
        }
      }
      final msg = body['message'] as String?;
      return Exception(msg ?? '$fallback (HTTP ${response.statusCode})');
    } catch (_) {
      return Exception('$fallback (HTTP ${response.statusCode})');
    }
  }
}
