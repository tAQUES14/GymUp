import 'dart:convert';
import '../../../core/api/api_service.dart';
import 'models/workout_plan_model.dart';

class WorkoutPlanApiService {
  final _api = ApiService();

  /// GET /api/workout-plan/today
  /// Returns null if no plan is assigned (404).
  /// Throws on other errors.
  Future<TodayWorkoutPlan?> getTodayWorkout() async {
    try {
      final response = await _api.get('/workout-plan/today');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TodayWorkoutPlan.fromJson(data);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('404')) {
        return null;
      }
      rethrow;
    }
  }
}
