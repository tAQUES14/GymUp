import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import 'challenge_api_service.dart';

class ChallengeDetailsPage extends StatefulWidget {
  final ChallengeData challenge;

  const ChallengeDetailsPage({super.key, required this.challenge});

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  List<ChallengeRankingEntry>? _ranking;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final ranking = await ChallengeApiService().getRanking(widget.challenge.id);
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ranking = [];
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Desafio',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const GymUpLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(challenge),
                  const SizedBox(height: 20),
                  _buildProgress(challenge),
                  const SizedBox(height: 24),
                  _buildRankingSection(challenge),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ChallengeData challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  challenge.isCompetitive
                      ? Icons.emoji_events_rounded
                      : Icons.flag_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: AppTypography.h3.copyWith(color: AppColors.warning),
                    ),
                    Text(
                      challenge.isCompetitive ? 'Desafio competitivo' : 'Desafio simples',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (challenge.description != null && challenge.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              challenge.description!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Progresso do usuário ──────────────────────────────────────────────────

  Widget _buildProgress(ChallengeData challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu progresso', style: AppTypography.h3),
        const SizedBox(height: 12),
        if (challenge.isSimple) _buildSimpleProgress(challenge),
        if (challenge.isCompetitive) _buildCompetitiveProgress(challenge),
      ],
    );
  }

  Widget _buildSimpleProgress(ChallengeData challenge) {
    final current  = challenge.myWorkouts ?? 0;
    final goal     = challenge.goalWorkouts ?? 1;
    final done     = challenge.goalCompleted ?? false;
    final progress = (current / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (done)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Meta concluida! Parabens!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$current / $goal treinos',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faltam ${(goal - current).clamp(0, goal)} treinos para completar o desafio',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompetitiveProgress(ChallengeData challenge) {
    final position    = challenge.myPosition;
    final points      = challenge.myTotalPoints ?? 0;
    final weekWorkouts = challenge.myWorkoutsThisWeek ?? 0;
    final maxWeek     = challenge.maxWeeklyWorkouts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position != null)
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$position\u00ba lugar no ranking',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.sports_score_rounded, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Treine para entrar no ranking',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.fitness_center_rounded,
                  value: maxWeek != null ? '$weekWorkouts / $maxWeek' : '$weekWorkouts',
                  label: 'treinos esta semana',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  icon: Icons.star_rounded,
                  value: '$points pts',
                  label: 'pontos acumulados',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ranking ───────────────────────────────────────────────────────────────

  Widget _buildRankingSection(ChallengeData challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ranking', style: AppTypography.h3),
        const SizedBox(height: 12),
        if (_hasError)
          Text(
            'Nao foi possivel carregar o ranking.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          )
        else if (_ranking == null || _ranking!.isEmpty)
          Text(
            'Nenhum participante ainda.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ranking!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildRankingRow(_ranking![i], challenge.isCompetitive),
          ),
      ],
    );
  }

  Widget _buildRankingRow(ChallengeRankingEntry entry, bool isCompetitive) {
    final isTop3 = entry.position <= 3;
    final positionColor = switch (entry.position) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textSecondary,
    };

    final valueText = isCompetitive
        ? '${entry.totalPoints ?? 0} pts'
        : '${entry.workouts ?? 0} treinos${entry.goalCompleted == true ? ' ✓' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3
            ? positionColor.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? positionColor.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.position}º',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: isTop3 ? positionColor : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.userName,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            valueText,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: isTop3 ? positionColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
