import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gymup_card.dart';
import '../../../core/widgets/gymup_button.dart';

class DailyWorkoutCard extends StatelessWidget {
  final String workoutName;
  final String duration;
  final String level;
  final VoidCallback? onTap;

  const DailyWorkoutCard({
    super.key,
    this.workoutName = 'Treino A - Peito e Tríceps',
    this.duration = '45 min',
    this.level = 'Intermediário',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Treino do Dia',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workoutName,
            style: AppTypography.h3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(Icons.timer, duration),
              const SizedBox(width: 12),
              _buildTag(Icons.bar_chart, level),
            ],
          ),
          const SizedBox(height: 16),
          GymUpButton(
            label: 'Iniciar Treino',
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
