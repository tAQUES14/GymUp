import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_icon_box.dart';

class DailyWorkoutCard extends StatelessWidget {
  final String workoutName;
  final String duration;
  final String level;
  final String? dayLabel;
  final VoidCallback? onTap;

  const DailyWorkoutCard({
    super.key,
    this.workoutName = 'Nenhum treino cadastrado',
    this.duration = '--',
    this.level = '--',
    this.dayLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasWorkout = workoutName != 'Nenhum treino cadastrado';

    return Container(
      decoration: BoxDecoration(
        gradient: hasWorkout
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blue, AppColors.blueDark],
              )
            : null,
        color: hasWorkout ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasWorkout
                ? AppColors.blue.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: hasWorkout ? _buildContent() : _buildEmpty(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rótulo do dia
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 11),
              const SizedBox(width: 5),
              Text(
                dayLabel != null ? 'HOJE · ${dayLabel!.toUpperCase()}' : 'TREINO DE HOJE',
                style: AppText.pjs(
                  size: 10, weight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Nome do treino
        Text(
          workoutName,
          style: AppText.pjs(size: 20, weight: FontWeight.w800, color: Colors.white),
        ),

        const SizedBox(height: 12),

        // Duração e nível
        Row(
          children: [
            _buildTag(Icons.timer_outlined, duration),
            const SizedBox(width: 16),
            _buildTag(Icons.bar_chart_rounded, level),
          ],
        ),

        const SizedBox(height: 24),

        // Botão de ação
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Iniciar treino',
              style: AppText.pjs(size: 14, weight: FontWeight.w700, color: AppColors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: [
        GymIconBox(
          icon: Icons.fitness_center_rounded,
          bg: Colors.grey.shade100,
          color: Colors.grey.shade400,
          size: GymIconSize.md,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nenhum treino cadastrado', style: AppText.itemTitle),
              const SizedBox(height: 2),
              Text(
                'Crie um treino na aba Treinos para começar.',
                style: AppText.subtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppText.pjs(
            size: 12, weight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
