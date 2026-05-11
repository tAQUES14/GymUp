import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DailyStreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;

  /// Nome do plano de treino ativo, se houver.
  /// Null indica que o aluno ainda não tem plano atribuído.
  final String? planName;

  const DailyStreakCard({
    super.key,
    this.streak = 0,
    this.bestStreak = 0,
    this.planName,
  });

  @override
  Widget build(BuildContext context) {
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
          // ── Header: chama + contador ──────────────────────────────
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak ${streak == 1 ? 'dia' : 'dias'} consecutivos',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (bestStreak > 0)
                    Text(
                      '🏆 Recorde: $bestStreak ${bestStreak == 1 ? 'dia' : 'dias'}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Info do plano ─────────────────────────────────────────
          const SizedBox(height: 10),
          if (planName != null)
            Text(
              'Plano: $planName',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Sem plano de treino — aguarde seu treinador atribuir um plano.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
