import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_card.dart';

class DailyStreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final String? planName;

  const DailyStreakCard({
    super.key,
    this.streak = 0,
    this.bestStreak = 0,
    this.planName,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      radius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak ${streak == 1 ? 'dia' : 'dias'} consecutivos',
                    style: AppText.pjs(size: 16, weight: FontWeight.w800, color: AppColors.ink),
                  ),
                  if (bestStreak > 0)
                    Text(
                      '🏆 Recorde: $bestStreak ${bestStreak == 1 ? 'dia' : 'dias'}',
                      style: AppText.subtitle,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (planName != null)
            Text(
              'Plano: $planName',
              style: AppText.subtitle.copyWith(
                color: AppColors.inkMuted, fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Sem plano de treino — aguarde seu treinador atribuir um plano.',
              style: AppText.subtitle.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}
