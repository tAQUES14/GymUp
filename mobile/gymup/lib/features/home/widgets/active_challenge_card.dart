import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_progress_bar.dart';
import '../../challenges/challenge_api_service.dart';

class ActiveChallengeCard extends StatelessWidget {
  final ChallengeData challenge;
  final VoidCallback? onTap;

  const ActiveChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (challenge.isSimple)      _buildSimpleProgress(),
            if (challenge.isCompetitive) _buildCompetitiveInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: Icon(
            challenge.isCompetitive
                ? Icons.emoji_events_rounded
                : Icons.flag_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.name,
                style: AppText.itemTitle.copyWith(color: AppColors.orange),
              ),
              Text(
                challenge.isCompetitive
                    ? 'Desafio competitivo'
                    : 'Desafio simples',
                style: AppText.subtitle,
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.orange.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  Widget _buildSimpleProgress() {
    final done      = challenge.goalCompleted ?? false;
    final current   = challenge.myWorkouts ?? 0;
    final goal      = challenge.goalWorkouts ?? 1;
    final remaining = (goal - current).clamp(0, goal);
    final progress  = (current / goal).clamp(0.0, 1.0);

    if (done) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
          const SizedBox(width: 6),
          Text(
            'Meta concluída! Parabéns!',
            style: AppText.subtitle.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Treine $goal vezes', style: AppText.subtitle),
            Text(
              '$current / $goal treinos',
              style: AppText.subtitle.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GymProgressBar(
          value: progress,
          color: AppColors.orange,
          showLabel: false,
          height: 6,
        ),
        const SizedBox(height: 6),
        Text(
          remaining == 1 ? 'Falta $remaining treino' : 'Faltam $remaining treinos',
          style: AppText.subtitle,
        ),
      ],
    );
  }

  Widget _buildCompetitiveInfo() {
    final weekWorkouts = challenge.myWorkoutsThisWeek ?? 0;
    final maxWeek      = challenge.maxWeeklyWorkouts;
    final totalPoints  = challenge.myTotalPoints ?? 0;
    final position     = challenge.myPosition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (position != null) ...[
          _buildPositionBadge(position),
          const SizedBox(height: 10),
        ] else ...[
          _buildNoPositionHint(),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _buildStat(
                icon:  Icons.fitness_center_rounded,
                value: maxWeek != null ? '$weekWorkouts / $maxWeek' : '$weekWorkouts',
                label: 'treinos esta semana',
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.orange.withValues(alpha: 0.20),
            ),
            Expanded(
              child: _buildStat(
                icon:  Icons.star_rounded,
                value: '$totalPoints',
                label: 'pts acumulados',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoPositionHint() {
    return Row(
      children: [
        Icon(Icons.sports_score_rounded, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: 6),
        Text(
          'Treine para entrar no ranking',
          style: AppText.subtitle.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildPositionBadge(int position) {
    return Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
        const SizedBox(width: 6),
        Text(
          'Você está em: ${_positionLabel(position)} lugar',
          style: AppText.subtitle.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  String _positionLabel(int position) {
    switch (position) {
      case 1: return '1º';
      case 2: return '2º';
      case 3: return '3º';
      default: return '$positionº';
    }
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.orange),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppText.itemTitle),
              Text(label, style: AppText.subtitle),
            ],
          ),
        ],
      ),
    );
  }
}
