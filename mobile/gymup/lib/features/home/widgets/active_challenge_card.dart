import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
          color: AppColors.warning.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (challenge.isSimple)     _buildSimpleProgress(),
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
            color: AppColors.warning,
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
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
              Text(
                challenge.isCompetitive
                    ? 'Desafio competitivo'
                    : 'Desafio simples',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.warning.withValues(alpha: 0.6),
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
          const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          Text(
            'Meta concluida! Parabens!',
            style: AppTypography.caption.copyWith(
              color: AppColors.accent,
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
            Text(
              'Treine $goal vezes',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$current / $goal treinos',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          remaining == 1 ? 'Falta $remaining treino' : 'Faltam $remaining treinos',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
              color: AppColors.warning.withValues(alpha: 0.20),
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
        Icon(
          Icons.sports_score_rounded,
          size: 16,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Treine para entrar no ranking',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionBadge(int position) {
    final label = _positionLabel(position);

    return Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
        const SizedBox(width: 6),
        Text(
          'Voce esta em: $label lugar',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _positionLabel(int position) {
    switch (position) {
      case 1: return '1o';
      case 2: return '2o';
      case 3: return '3o';
      default: return '${position}o';
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
          Icon(icon, size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
