class Redemption {
  final int id;
  final int pointsSpent;
  final String status;
  final DateTime createdAt;
  final String? rewardName;
  final String? rewardImageUrl;

  const Redemption({
    required this.id,
    required this.pointsSpent,
    required this.status,
    required this.createdAt,
    this.rewardName,
    this.rewardImageUrl,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] as Map<String, dynamic>?;
    return Redemption(
      id:             json['id'] as int,
      pointsSpent:    (json['points_spent'] as num).toInt(),
      status:         json['status'] as String? ?? 'pending',
      createdAt:      DateTime.parse(json['created_at'] as String),
      rewardName:     reward?['name'] as String?,
      rewardImageUrl: reward?['image_url'] as String?,
    );
  }
}
