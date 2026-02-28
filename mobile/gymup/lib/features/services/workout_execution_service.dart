import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutExecutionService {

  // 🔥 COLOQUE AQUI SEU IP LOCAL DO LARAVEL
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // 🔥 COLOQUE AQUI TEMPORARIAMENTE SEU TOKEN
  static const String token = "1|02mRPREYN9HuQPcLS1eAgPIsKKzJ3EMZKiieVRyF76877f75";

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> finishWorkout({
    required int workoutId,
    required int durationMinutes,
    required int setsCompleted,
    required int setsTotal,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workout/finish'),
      headers: _headers,
      body: jsonEncode({
        'workout_id': workoutId,
        'duration_minutes': durationMinutes,
        'sets_completed': setsCompleted,
        'sets_total': setsTotal,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }
}