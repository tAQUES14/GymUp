import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class DailyWorkoutCard extends StatelessWidget {
  final String workoutName;
  final String duration;
  final String level;
  final VoidCallback? onTap;

  const DailyWorkoutCard({
    super.key,
    this.workoutName = 'Nenhum treino cadastrado',
    this.duration = '--',
    this.level = '--',
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
                colors: [_kBlue, _kBlueDark],
              )
            : null,
        color: hasWorkout ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasWorkout
                ? _kBlue.withValues(alpha: 0.30)
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
        // Rótulo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'TREINO DE HOJE',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Nome do treino
        Text(
          workoutName,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
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

        // Botão
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Iniciar treino',
              style: AppTypography.button.copyWith(
                color: _kBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhum treino cadastrado',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Crie um treino na aba Treinos para começar.',
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
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
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
