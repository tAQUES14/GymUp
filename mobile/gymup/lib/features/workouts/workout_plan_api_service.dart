import 'dart:convert';
import '../../../core/api/api_service.dart';
import 'models/workout_plan_model.dart';

class WorkoutPlanApiService {
  final _api = ApiService();

  /// GET /api/workout-plan/today
  /// Returns null if no plan is assigned (404) or user is unauthenticated (401).
  /// Throws on unexpected errors.
  Future<TodayWorkoutPlan?> getTodayWorkout() async {
    final response = await _api.get('/workout-plan/today');

    if (response.statusCode == 404 || response.statusCode == 401) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('GET /workout-plan/today failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TodayWorkoutPlan.fromJson(data);
  }
}
