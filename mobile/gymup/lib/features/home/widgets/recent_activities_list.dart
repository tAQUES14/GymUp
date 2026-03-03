import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workouts/workout_api_service.dart';

String _formatarTempoRelativo(DateTime date) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final local = date.toLocal();
  final diaEvento = DateTime(local.year, local.month, local.day);
  final diferenca = hoje.difference(diaEvento).inDays;

  if (diferenca <= 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';
  return 'Há $diferenca dias';
}

/// Exibe as últimas atividades de treino com dados vindos da API REST.
class RecentActivitiesList extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivitiesList({super.key, this.activities = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimas atividades', style: AppTypography.h3),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Nenhuma atividade ainda.', style: AppTypography.caption),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final tempoRelativo = _formatarTempoRelativo(activity.date);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Treino realizado',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(tempoRelativo, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(
                      activity.points > 0
                          ? '+${activity.points} pts'
                          : 'Sem pontos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: activity.points > 0
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
