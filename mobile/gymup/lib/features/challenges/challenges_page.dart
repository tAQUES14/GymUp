import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../home/widgets/active_challenge_card.dart';
import 'challenge_api_service.dart';
import 'challenge_details_page.dart';
import 'achievement_api_service.dart';
import 'achievements_list.dart';
import 'my_achievements_page.dart';

// Azul principal conforme solicitado
const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class _PageData {
  final ChallengeData? challenge;
  final List<ChallengeData> personalChallenges;
  final List<Achievement> achievements;

  const _PageData({
    required this.challenge,
    required this.personalChallenges,
    required this.achievements,
  });
}

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final _challengeApi   = ChallengeApiService();
  final _achievementApi = AchievementApiService();

  _PageData? _data;
  bool _isLoading = true;
  bool _hasError  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final results = await Future.wait([
        _challengeApi.getActiveChallenges().catchError(
              (_) => const ActiveChallengesData(community: null, personal: []),
            ),
        _achievementApi.getAchievements().catchError((_) => <Achievement>[]),
      ]);

      if (!mounted) return;

      final challenges = results[0] as ActiveChallengesData;
      final all = results[1] as List<Achievement>;

      // Ordem: desbloqueadas → em progresso → bloqueadas
      final sorted = [
        ...all.where((a) => a.unlocked),
        ...all.where((a) => a.isInProgress),
        ...all.where((a) => a.isLocked),
      ];

      setState(() {
        _data = _PageData(
          challenge: challenges.community,
          personalChallenges: challenges.personal,
          achievements: sorted,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Desafios',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const GymUpLoading()
          : RefreshIndicator(
              onRefresh: _load,
              color: _kBlue,
              child: _hasError ? _buildError() : _buildContent(),
            ),
    );
  }

  // ── Estado de erro ────────────────────────────────────────────────────────

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded, size: 34,
                      color: Colors.grey.shade400),
                ),
                const SizedBox(height: 20),
                Text('Sem conexão',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Não foi possível carregar seus dados.\nVerifique sua conexão e tente novamente.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tentar novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Conteúdo principal ────────────────────────────────────────────────────

  Widget _buildContent() {
    final data       = _data!;
    final total      = data.achievements.length;
    final unlocked   = data.achievements.where((a) => a.unlocked).length;
    final inProgress = data.achievements.where((a) => a.isInProgress).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner hero ────────────────────────────────────────────────
            _buildHero(unlocked: unlocked, total: total, inProgress: inProgress),

            // ── Corpo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Desafio da academia ──────────────────────────────────
                  _buildSectionHeader(
                    icon: Icons.flag_rounded,
                    title: 'Desafio da academia',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  if (data.challenge != null)
                    ActiveChallengeCard(
                      challenge: data.challenge!,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChallengeDetailsPage(challenge: data.challenge!),
                        ),
                      ).then((_) => _load()),
                    )
                  else
                    _buildNoChallenge(),

                  if (data.personalChallenges.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.track_changes_rounded,
                      title: 'Desafios pessoais',
                      color: _kBlue,
                      trailing: '${data.personalChallenges.length}',
                    ),
                    const SizedBox(height: 12),
                    for (final challenge in data.personalChallenges)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ActiveChallengeCard(
                          challenge: challenge,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChallengeDetailsPage(challenge: challenge),
                            ),
                          ).then((_) => _load()),
                        ),
                      ),
                  ],

                  const SizedBox(height: 12),
                  _buildAchievementsShortcut(
                    unlocked: unlocked,
                    total: total,
                    onTap: () => _openAchievements(data.achievements),
                  ),

                  // ── Conquistas ───────────────────────────────────────────
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    icon: Icons.emoji_events_rounded,
                    title: 'Conquistas',
                    color: _kBlue,
                    trailing: 'Ver todas',
                    onTrailingTap: () => _openAchievements(data.achievements),
                  ),
                  const SizedBox(height: 12),
                  AchievementsList(achievements: data.achievements.take(3).toList()),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _openAchievements(List<Achievement> achievements) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyAchievementsPage(initialAchievements: achievements),
      ),
    );
    if (mounted) _load();
  }

  // ── Banner hero com gradiente azul ────────────────────────────────────────

  Widget _buildHero({
    required int unlocked,
    required int total,
    required int inProgress,
  }) {
    final ratio = total > 0 ? unlocked / total : 0.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlueDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progresso geral
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$unlocked de $total conquistas desbloqueadas',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          // Chips de status
          if (inProgress > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    '$inProgress em progresso',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Cabeçalho de seção ────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.h3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailing,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAchievementsShortcut({
    required int unlocked,
    required int total,
    required VoidCallback onTap,
  }) {
    final ratio = total > 0 ? unlocked / total : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBlue.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: _kBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minhas conquistas',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$unlocked de $total desbloqueadas',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: _kBlue.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: _kBlue,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sem desafio ativo ─────────────────────────────────────────────────────

  Widget _buildNoChallenge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Icon(Icons.flag_outlined, size: 20, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum desafio ativo',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Quando a academia criar um desafio, ele aparecerá aqui.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
