import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

const _kBlue = Color(0xFF2563EB);

/// Shows weekly workout goal progress (workouts done vs goal, progress bar).
/// This is a separate concept from the daily streak — it tracks weekly volume.
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
    final int faltam = goalMet ? 0 : weeklyGoal - workoutsDone;
    final double ratio = (workoutsDone / weeklyGoal).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta semanal',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$workoutsDone',
                style: AppTypography.h2.copyWith(
                  color: goalMet ? AppColors.accent : _kBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(
                  ' / $weeklyGoal treinos',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalMet ? AppColors.accent : _kBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goalMet
                ? '✓ Meta da semana concluída!'
                : 'Falta${faltam == 1 ? '' : 'm'} $faltam treino${faltam == 1 ? '' : 's'} esta semana',
            style: AppTypography.caption.copyWith(
              color: goalMet ? AppColors.accent : AppColors.textSecondary,
              fontWeight: goalMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward-compatible alias. Prefer WeeklyGoalCard for new code.
@Deprecated('Use WeeklyGoalCard instead')
class WeeklyGoalSection extends WeeklyGoalCard {
  const WeeklyGoalSection({
    super.key,
    super.workoutsDone,
    super.weeklyGoal,
    // streak and bestStreak are no longer shown here — use DailyStreakCard
    int streak = 0,
    int bestStreak = 0,
  });
}
