import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workouts/workout_api_service.dart';

String _relativeTime(DateTime date) {
  final today = DateTime.now();
  final d     = DateTime(today.year, today.month, today.day);
  final local = date.toLocal();
  final event = DateTime(local.year, local.month, local.day);
  final diff  = d.difference(event).inDays;

  if (diff <= 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return 'Há $diff dias';
}

class RecentActivitiesList extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivitiesList({super.key, this.activities = const []});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, color: Colors.grey.shade400, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhuma atividade ainda',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Seus treinos aparecerão aqui.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 68,
          color: Colors.grey.shade100,
        ),
        itemBuilder: (_, i) => _ActivityItem(activity: activities[i]),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final tempoRelativo = _relativeTime(activity.date);
    final temPontos     = activity.points > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Treino concluído',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tempoRelativo,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Pontos
          Text(
            temPontos ? '+${activity.points} pts' : 'Sem pontos',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: temPontos ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
