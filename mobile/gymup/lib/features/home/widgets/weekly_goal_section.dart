import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_card.dart';
import '../../../core/widgets/gym_progress_bar.dart';

class WeeklyGoalCard extends StatelessWidget {
  final int workoutsDone;
  final int weeklyGoal;

  const WeeklyGoalCard({
    super.key,
    this.workoutsDone = 0,
    this.weeklyGoal = 3,
  });

  @override
  Widget build(BuildContext context) {
    final bool goalMet = workoutsDone >= weeklyGoal;
    final int faltam   = goalMet ? 0 : weeklyGoal - workoutsDone;
    final double ratio = (workoutsDone / weeklyGoal).clamp(0.0, 1.0);
    final Color accent = goalMet ? AppColors.green : AppColors.blue;

    return GymCard(
      radius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meta semanal', style: AppText.cardLabel),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$workoutsDone',
                style: AppText.statValue.copyWith(color: accent),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(
                  ' / $weeklyGoal treinos',
                  style: AppText.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GymProgressBar(value: ratio, color: accent, showLabel: false, height: 6),
          const SizedBox(height: 8),
          Text(
            goalMet
                ? '✓ Meta da semana concluída!'
                : 'Falta${faltam == 1 ? '' : 'm'} $faltam treino${faltam == 1 ? '' : 's'} esta semana',
            style: AppText.subtitle.copyWith(
              color: goalMet ? AppColors.green : AppColors.inkMuted,
              fontWeight: goalMet ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

@Deprecated('Use WeeklyGoalCard instead')
class WeeklyGoalSection extends WeeklyGoalCard {
  const WeeklyGoalSection({
    super.key,
    super.workoutsDone,
    super.weeklyGoal,
    int streak = 0,
    int bestStreak = 0,
  });
}
