import 'dart:convert';
import '../../../core/api/api_service.dart';

class Achievement {
  final int? id;
  final String? code;
  final String title;
  final String description;
  final String? metric;
  final String? icon;
  final int progress;
  final int target;
  final int pointsReward;
  final bool unlocked;

  const Achievement({
    this.id,
    this.code,
    required this.title,
    required this.description,
    this.metric,
    this.icon,
    required this.progress,
    required this.target,
    required this.pointsReward,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: (json['id'] as num?)?.toInt(),
      code: json['code'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      metric: json['metric'] as String?,
      icon: json['icon'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: ((json['target'] ?? json['target_value']) as num).toInt(),
      pointsReward:
          ((json['pointsReward'] ?? json['points_reward']) as num).toInt(),
      unlocked: json['unlocked'] == true,
    );
  }

  bool get isInProgress => !unlocked && progress > 0;
  bool get isLocked     => !unlocked && progress == 0;
  bool get isStreak => metric == 'streak_days' || icon == 'streak';
  bool get isWorkout => metric == 'workouts_total' || icon == 'fitness';
}

class AchievementApiService {
  final _api = ApiService();

  Future<List<Achievement>> getAchievements() async {
    final response = await _api.get('/achievements');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final list = (body is List ? body : body['achievements'] as List<dynamic>);
      return list
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
