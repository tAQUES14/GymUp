import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_card.dart';
import '../../../core/widgets/gym_icon_box.dart';
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
      return GymCard(
        radius: 18,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GymIconBox(
              icon: Icons.inbox_rounded,
              bg: AppColors.blueTint,
              color: AppColors.inkLight,
              size: GymIconSize.sm,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nenhuma atividade ainda', style: AppText.itemTitle),
                Text('Seus treinos aparecerão aqui.', style: AppText.subtitle),
              ],
            ),
          ],
        ),
      );
    }

    return GymCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, _) => Divider(
          height: 1, indent: 72,
          color: AppColors.inkLight.withValues(alpha: 0.15),
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
          GymIconBox(
            icon: Icons.fitness_center_rounded,
            bg: AppColors.greenTint,
            color: AppColors.green,
            size: GymIconSize.sm,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treino concluído', style: AppText.timelineTitle),
                const SizedBox(height: 2),
                Text(tempoRelativo, style: AppText.subtitle),
              ],
            ),
          ),
          Text(
            temPontos ? '+${activity.points} pts' : 'Sem pontos',
            style: AppText.metricSmall.copyWith(
              color: temPontos ? AppColors.green : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
