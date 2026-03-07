import 'dart:convert';
import '../../../core/api/api_service.dart';

class ChallengeData {
  final int id;
  final String type; // 'simple' | 'competitive'
  final String name;
  final String? description;
  final String startsAt;
  final String endsAt;
  final String status;

  // Simples
  final int? goalWorkouts;
  final int? rewardPoints;
  final int? myWorkouts;
  final bool? goalCompleted;

  // Competitivo
  final int? minWeeklyWorkouts;
  final int? maxWeeklyWorkouts;
  final int? myWorkoutsThisWeek;
  final int? myTotalPoints;
  final int? myPosition;

  const ChallengeData({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.goalWorkouts,
    this.rewardPoints,
    this.myWorkouts,
    this.goalCompleted,
    this.minWeeklyWorkouts,
    this.maxWeeklyWorkouts,
    this.myWorkoutsThisWeek,
    this.myTotalPoints,
    this.myPosition,
  });

  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    return ChallengeData(
      id:          json['id'] as int,
      type:        json['type'] as String,
      name:        json['name'] as String,
      description: json['description'] as String?,
      startsAt:    json['starts_at'] as String,
      endsAt:      json['ends_at'] as String,
      status:      json['status'] as String,
      goalWorkouts:      (json['goal_workouts'] as num?)?.toInt(),
      rewardPoints:      (json['reward_points'] as num?)?.toInt(),
      myWorkouts:        (json['my_workouts'] as num?)?.toInt(),
      goalCompleted:     json['goal_completed'] as bool?,
      minWeeklyWorkouts: (json['min_weekly_workouts'] as num?)?.toInt(),
      maxWeeklyWorkouts: (json['max_weekly_workouts'] as num?)?.toInt(),
      myWorkoutsThisWeek:(json['my_workouts_this_week'] as num?)?.toInt(),
      myTotalPoints:     (json['my_total_points'] as num?)?.toInt(),
      myPosition:        (json['my_position'] as num?)?.toInt(),
    );
  }

  bool get isSimple      => type == 'simple';
  bool get isCompetitive => type == 'competitive';
}

class ChallengeRankingEntry {
  final int position;
  final int userId;
  final String userName;
  final int? totalPoints;    // competitive
  final int? workouts;       // simple
  final bool? goalCompleted; // simple

  const ChallengeRankingEntry({
    required this.position,
    required this.userId,
    required this.userName,
    this.totalPoints,
    this.workouts,
    this.goalCompleted,
  });

  factory ChallengeRankingEntry.fromJson(Map<String, dynamic> json, int index) {
    return ChallengeRankingEntry(
      position:     (json['position'] as num?)?.toInt() ?? (index + 1),
      userId:       (json['user_id'] as num).toInt(),
      userName:     json['user_name'] as String,
      totalPoints:  (json['total_points'] as num?)?.toInt(),
      workouts:     (json['workouts'] as num?)?.toInt(),
      goalCompleted: json['goal_completed'] as bool?,
    );
  }
}

class ChallengeApiService {
  final _api = ApiService();

  Future<ChallengeData?> getActiveChallenge() async {
    final response = await _api.get('/challenges/active');

    if (response.statusCode == 200) {
      final body      = jsonDecode(response.body) as Map<String, dynamic>;
      final challenge = body['challenge'];
      if (challenge == null) return null;
      return ChallengeData.fromJson(challenge as Map<String, dynamic>);
    }

    throw Exception('Erro ao buscar desafio ativo.');
  }

  Future<List<ChallengeRankingEntry>> getRanking(int id) async {
    final response = await _api.get('/challenges/$id/ranking');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['ranking'] as List<dynamic>;
      return list
          .asMap()
          .entries
          .map((e) => ChallengeRankingEntry.fromJson(
                e.value as Map<String, dynamic>,
                e.key,
              ))
          .toList();
    }

    throw Exception('Erro ao buscar ranking do desafio.');
  }
}
