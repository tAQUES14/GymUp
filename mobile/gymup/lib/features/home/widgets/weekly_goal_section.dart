import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gymup_card.dart';

class WeeklyGoalSection extends StatelessWidget {
  final int workoutsDone;
  final int weeklyGoal;
  final int streak;

  const WeeklyGoalSection({
    super.key,
    this.workoutsDone = 0,
    this.weeklyGoal = 3,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool weeklyGoalMet = workoutsDone >= weeklyGoal;
    final int faltam = weeklyGoalMet ? 0 : weeklyGoal - workoutsDone;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: GymUpCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meta Semanal', style: AppTypography.caption),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$workoutsDone',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '/$weeklyGoal treinos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (workoutsDone / weeklyGoal).clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      weeklyGoalMet ? AppColors.accent : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weeklyGoalMet
                      ? 'Meta da semana concluída!'
                      : 'Falta${faltam == 1 ? '' : 'm'} $faltam treino${faltam == 1 ? '' : 's'} para manter seu streak',
                  style: AppTypography.caption.copyWith(
                    color: weeklyGoalMet
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: weeklyGoalMet
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: GymUpCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Streak', style: AppTypography.caption),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streak == 1 ? '1 sem.' : '$streak sem.',
                      style: AppTypography.h3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
