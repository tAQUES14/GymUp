import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gymup_card.dart';

class PointsCard extends StatelessWidget {
  final int pontos;
  final String nextRewardName;
  final int pointsToNextReward;

  const PointsCard({
    super.key,
    required this.pontos,
    this.nextRewardName = 'Camiseta GymUp',
    this.pointsToNextReward = 150,
  });

  @override
  Widget build(BuildContext context) {
    return GymUpCard(
      color: Colors.transparent, // Using gradient container instead
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEUS PONTOS',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: pontos),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Text(
                          '$value',
                          style: AppTypography.h1.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Faltam $pointsToNextReward pontos para $nextRewardName',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.7, // Mock progress
                backgroundColor: Colors.black.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
