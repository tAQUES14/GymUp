import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../workouts/workout_api_service.dart';

class HomeTodayActivity extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onViewAll;

  const HomeTodayActivity({
    super.key,
    required this.data,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Atividade de hoje', style: AppText.sectionTitle),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text('Ver tudo', style: AppText.link),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return _TimelineItem(
                item: items[i],
                isLast: i == items.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  List<_ActivityItem> _buildItems() {
    final result = <_ActivityItem>[];

    if (data.hasCheckedInToday) {
      result.add(const _ActivityItem(
        iconBg: AppColors.blueTint,
        icon: Icons.qr_code_2_rounded,
        iconColor: AppColors.blue,
        title: 'Check-in realizado',
        subtitle: 'Hoje · Recepção',
        showCheck: true,
      ));
    }

    if (data.hasActiveSession) {
      result.add(const _ActivityItem(
        iconBg: AppColors.orangeTint,
        icon: Icons.show_chart_rounded,
        iconColor: AppColors.orange,
        title: 'Treino em andamento',
        subtitle: 'Upper Body Power · Exercício 6/10',
        type: _ItemType.progress,
        progress: 0.65,
      ));
    } else if (data.hasCompletedToday) {
      result.add(const _ActivityItem(
        iconBg: AppColors.orangeTint,
        icon: Icons.fitness_center_rounded,
        iconColor: AppColors.orange,
        title: 'Treino concluído',
        subtitle: 'Hoje · Muito bem!',
        showCheck: true,
      ));
    }

    final done = data.workoutsDoneThisWeek;
    final goal = data.weeklyGoal;
    final remaining = (goal - done).clamp(0, goal);
    final goalMet = goal > 0 && done >= goal;

    result.add(_ActivityItem(
      iconBg: AppColors.greenTint,
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.green,
      title: goalMet ? 'Meta semanal concluída!' : 'Meta semanal quase concluída',
      subtitle: goalMet
          ? '$done de $goal treinos concluídos!'
          : '$done de $goal treinos · faltam $remaining treino${remaining == 1 ? '' : 's'}',
    ));

    return result;
  }
}

enum _ItemType { plain, progress }

class _ActivityItem {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final _ItemType type;
  final double progress;
  final bool showCheck;

  const _ActivityItem({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.type = _ItemType.plain,
    this.progress = 0.0,
    this.showCheck = false,
  });
}

class _TimelineItem extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;

  const _TimelineItem({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(item.icon, size: 16, color: item.iconColor),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: item.type == _ItemType.progress ? 66 : 40,
                  margin: const EdgeInsets.only(top: 2),
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.title, style: AppText.timelineTitle),
                    ),
                    if (item.showCheck)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: AppText.subtitle),
                if (item.type == _ItemType.progress) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 6,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: constraints.maxWidth *
                                      item.progress.clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientPrimary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.progress * 100).round()}%',
                        style: AppText.metricSmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
