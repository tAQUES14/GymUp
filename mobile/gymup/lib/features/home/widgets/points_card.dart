import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_progress_bar.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF27AE60).withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    style: AppText.pjs(
                      size: 11, weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: pontos),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) => Text(
                      '$value',
                      style: AppText.sg(
                        size: 48, weight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Faltam $pointsToNextReward pontos para $nextRewardName',
            style: AppText.subtitleWhite,
          ),
          const SizedBox(height: 8),
          GymProgressBar(
            value: 0.7,
            color: Colors.white,
            bgColor: Colors.black.withValues(alpha: 0.10),
            showLabel: false,
            height: 6,
          ),
        ],
      ),
    );
  }
}
