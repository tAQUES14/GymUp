import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// Day convention matches backend (Carbon::dayOfWeek):
// 0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday,
// 4 = Thursday, 5 = Friday, 6 = Saturday
const _kDayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

// Display order: Seg Ter Qua Qui Sex Sáb Dom (Monday-first for Brazilian users)
const _kDisplayOrder = [1, 2, 3, 4, 5, 6, 0];

class DailyStreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;

  /// List of day_of_week values that are training days (0=Sun...6=Sat).
  /// Empty list means no schedule defined yet.
  final List<int> trainingDays;

  const DailyStreakCard({
    super.key,
    this.streak = 0,
    this.bestStreak = 0,
    this.trainingDays = const [],
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
          // ── Header row: flame + streak number ──────────────────────
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

          // ── Training day chips ──────────────────────────────────────
          if (trainingDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: _kDisplayOrder.map((day) {
                final isTrainingDay = trainingDays.contains(day);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DayChip(
                    label: _kDayLabels[day],
                    active: isTrainingDay,
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Sem agenda definida — aguarde seu treinador configurar.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool active;

  const _DayChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2563EB).withValues(alpha: 0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? const Color(0xFF2563EB).withValues(alpha: 0.40)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: active
              ? const Color(0xFF2563EB)
              : AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}
