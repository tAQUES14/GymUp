import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../challenges/challenge_api_service.dart';
import '../../workouts/models/workout_model.dart';
import '../../workouts/models/workout_plan_model.dart';
import '../../workouts/workout_api_service.dart';

class HomeQuickAccess extends StatelessWidget {
  final DashboardData data;
  final WorkoutModel? todayWorkout;
  final TodayWorkoutPlan? todayPlan;
  final ChallengeData? challengeData;
  final VoidCallback? onWorkoutTap;
  final VoidCallback? onChallengesTap;
  final VoidCallback? onAchievementsTap;
  final VoidCallback? onStoreTap;

  const HomeQuickAccess({
    super.key,
    required this.data,
    this.todayWorkout,
    this.todayPlan,
    this.challengeData,
    this.onWorkoutTap,
    this.onChallengesTap,
    this.onAchievementsTap,
    this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRestDay = todayPlan?.isRestDay ?? false;
    final challengeSubtitle =
        challengeData != null ? challengeData!.name : 'Nenhum desafio ativo';
    final pointsText = _formatPoints(data.pointsBalance);

    return Column(
      children: [
        _QuickTile(
          iconBg: AppColors.blueTint,
          icon: isRestDay ? Icons.self_improvement_rounded : Icons.fitness_center_rounded,
          iconColor: AppColors.blue,
          title: isRestDay ? 'Dia de descanso' : 'Treino do dia',
          subtitle: _workoutSubtitle(isRestDay),
          badge: _workoutBadge(isRestDay),
          onTap: onWorkoutTap,
        ),
        const SizedBox(height: 10),
        _QuickTile(
          iconBg: AppColors.orangeTint,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.orange,
          title: 'Desafios ativos',
          subtitle: challengeSubtitle,
          badge: (challengeData?.rewardPoints ?? 0) > 0
              ? _Badge(
                  label: '+${challengeData!.rewardPoints} pts',
                  bg: AppColors.orangeTint,
                  fg: AppColors.orangeDark,
                )
              : null,
          onTap: onChallengesTap,
        ),
        const SizedBox(height: 10),
        _QuickTile(
          iconBg: AppColors.blueTint,
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.blue,
          title: 'Minhas conquistas',
          subtitle: 'Acompanhe seus desafios pessoais',
          onTap: onAchievementsTap,
        ),
        const SizedBox(height: 10),
        _QuickTile(
          iconBg: AppColors.greenTint,
          icon: Icons.storefront_rounded,
          iconColor: AppColors.green,
          title: 'Loja de recompensas',
          subtitle: 'Troque seus $pointsText pontos',
          onTap: onStoreTap,
        ),
      ],
    );
  }

  _Badge _workoutBadge(bool isRestDay) {
    if (isRestDay) {
      return _Badge(label: 'OFF', bg: AppColors.ink, fg: AppColors.lime);
    }

    if (data.hasCompletedToday) {
      return _Badge(label: 'FEITO', bg: AppColors.green, fg: Colors.white);
    }

    return _Badge(label: 'HOJE', bg: AppColors.ink, fg: AppColors.lime);
  }

  String _workoutSubtitle(bool isRestDay) {
    if (isRestDay) {
      final planName = todayPlan?.planName.trim() ?? '';
      return planName.isEmpty
          ? 'Streak protegido - treino livre opcional'
          : 'Streak protegido - $planName';
    }

    if (data.hasCompletedToday) {
      if (todayWorkout != null) {
        return '${todayWorkout!.name} concluido hoje';
      }
      return 'Treino de hoje concluido!';
    }

    if (todayWorkout != null) {
      final duration = todayWorkout!.duration ?? 0;
      return '${todayWorkout!.name} - $duration min';
    }

    return 'Nenhum plano ativo';
  }

  static String _formatPoints(int pts) {
    if (pts >= 1000) {
      final thousands = pts ~/ 1000;
      final rest = pts % 1000;
      return '$thousands.${rest.toString().padLeft(3, '0')}';
    }
    return '$pts';
  }
}

class _Badge {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});
}

class _QuickTile extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final _Badge? badge;
  final VoidCallback? onTap;

  const _QuickTile({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.itemTitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle,
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badge!.bg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge!.label,
                  style: AppText.pjs(
                    size: 11,
                    weight: FontWeight.w700,
                    color: badge!.fg,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
