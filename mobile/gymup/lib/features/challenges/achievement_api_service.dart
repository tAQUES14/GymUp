import 'dart:convert';
import '../../../core/api/api_service.dart';

class Achievement {
  final String title;
  final String description;
  final int progress;
  final int target;
  final int pointsReward;
  final bool unlocked;

  const Achievement({
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.pointsReward,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title:        json['title'] as String,
      description:  json['description'] as String,
      progress:     (json['progress'] as num).toInt(),
      target:       (json['target'] as num).toInt(),
      pointsReward: (json['pointsReward'] as num).toInt(),
      unlocked:     json['unlocked'] as bool,
    );
  }

  bool get isInProgress => !unlocked && progress > 0;
  bool get isLocked     => !unlocked && progress == 0;
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
