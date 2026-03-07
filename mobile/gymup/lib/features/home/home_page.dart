import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../challenges/challenge_api_service.dart';
import '../challenges/challenge_details_page.dart';
import '../goals/goal_api_service.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/workout_api_service.dart';
import 'widgets/active_challenge_card.dart';
import 'widgets/home_header.dart';
import 'widgets/points_card.dart';
import 'widgets/weekly_goal_section.dart';
import 'widgets/daily_workout_card.dart';
import 'widgets/weekly_progress_bar.dart';
import 'widgets/recent_activities_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DashboardData?  _dashboardData;
  GoalData?       _goalData;
  ChallengeData?  _challengeData;

  /// Primeiro treino real do usuário. Nunca conterá IDs negativos.
  /// Null enquanto carrega ou se o usuário não tiver treinos cadastrados.
  WorkoutModel? _todayWorkout;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isStarting = false;

  // Contador de sequência: garante que apenas a resposta da chamada MAIS
  // RECENTE seja aplicada ao estado, descartando respostas de chamadas antigas
  // que chegarem depois (race condition em chamadas concorrentes).
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  /// Carrega dashboard e lista de treinos em paralelo.
  /// Garante que [_todayWorkout] sempre venha do backend (IDs positivos).
  Future<void> _loadDashboard() async {
    final seq = ++_loadSeq;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final api = WorkoutApiService();
      final results = await Future.wait<dynamic>([
        api.getDashboard(),
        api.getWorkouts(),
        GoalApiService().getCurrentGoal().catchError((_) => null),
        ChallengeApiService().getActiveChallenge().catchError((_) => null),
      ]);

      // Só aplica se ainda for a chamada mais recente e o widget estiver montado.
      if (!mounted || seq != _loadSeq) return;

      final data     = results[0] as DashboardData;
      final workouts = results[1] as List<WorkoutModel>;

      setState(() {
        _dashboardData  = data;
        _todayWorkout   = workouts.isNotEmpty ? workouts.first : null;
        _goalData       = results[2] as GoalData?;
        _challengeData  = results[3] as ChallengeData?;
        _isLoading      = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;

      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ── Navegação segura para execução ────────────────────────────────────────

  /// Navega para [/workout-step] com o treino real.
  /// Se o usuário não tiver treinos cadastrados, exibe aviso em vez de navegar.
  void _pushWorkoutStep() {
    if (_todayWorkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum treino cadastrado. Crie um treino na aba Treinos.',
          ),
        ),
      );
      return;
    }

    // Garantia extra: IDs negativos jamais devem chegar à execução.
    assert(
      _todayWorkout!.id > 0,
      'BUG: workout com ID inválido (${_todayWorkout!.id}) chegou à navegação.',
    );

    Navigator.of(context)
        .pushNamed('/workout-step', arguments: _todayWorkout)
        .then((_) => _loadDashboard());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: GymUpLoading(),
      );
    }

    if (_hasError || _dashboardData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erro ao carregar dados.', style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboardData!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(nome: data.name, photoUrl: null),
              const SizedBox(height: 24),

              PointsCard(pontos: data.pointsBalance),
              const SizedBox(height: 24),

              WeeklyGoalSection(
                streak: data.streak,
                workoutsDone: data.weeklyProgress.where((d) => d).length,
                weeklyGoal: data.weeklyGoal,
              ),
              const SizedBox(height: 24),

              _CheckInButton(
                hasCheckedInToday: data.hasCheckedInToday,
                hasCompletedToday: data.hasCompletedToday,
                onTap: data.hasCompletedToday
                    ? null
                    : _handleStartWorkout,
              ),
              const SizedBox(height: 16),

              if (data.hasActiveSession) ...[
                _buildResumeBanner(),
                const SizedBox(height: 16),
              ],

              DailyWorkoutCard(
                workoutName: _todayWorkout?.name ?? 'Nenhum treino cadastrado',
                duration: _todayWorkout != null
                    ? '${_todayWorkout!.duration ?? 0} min'
                    : '--',
                level: _todayWorkout?.level ?? '--',
                onTap: _isStarting ? null : _handleStartWorkout,
              ),
              const SizedBox(height: 24),

              WeeklyProgressBar(weeklyProgress: data.weeklyProgress),
              const SizedBox(height: 24),

              _buildGoalCard(),
              const SizedBox(height: 24),

              if (_challengeData != null) ...[
                ActiveChallengeCard(
                  challenge: _challengeData!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChallengeDetailsPage(challenge: _challengeData!),
                    ),
                  ).then((_) => _loadDashboard()),
                ),
                const SizedBox(height: 24),
              ],

              RecentActivitiesList(activities: data.recentActivities),
              const SizedBox(height: 24),

              _buildQuickActions(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card de Meta ──────────────────────────────────────────────────────────

  Widget _buildGoalCard() {
    // Sem meta: convite para criar
    if (_goalData == null) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/goals/create')
            .then((_) => _loadDashboard()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Defina sua meta',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    Text(
                      'Acompanhe sua evolução com uma meta pessoal.',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    }

    // Com meta: resumo compacto
    final goal = _goalData!;
    final deltaKg = (goal.targetWeight - goal.startWeight).abs();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/goals')
          .then((_) => _loadDashboard()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua meta: ${goal.goalTypeLabel}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    '${goal.startWeight.toStringAsFixed(1)} → ${goal.targetWeight.toStringAsFixed(1)} kg  (${deltaKg.toStringAsFixed(1)} kg)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.accent.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartWorkout() async {
    if (_isStarting) return;
    final data = _dashboardData!;

    // Retoma sessão ativa existente.
    if (data.hasActiveSession) {
      _pushWorkoutStep();
      return;
    }

    final bool alreadyHasSessionToday =
        data.hasActiveSession || data.hasCompletedToday;

    // Exige check-in antes de iniciar o treino.
    if (!alreadyHasSessionToday && !data.hasCheckedInToday) {
      Navigator.of(context)
          .pushNamed('/checkin')
          .then((_) => _loadDashboard());
      return;
    }

    // Treino extra: já completou hoje, não ganha pontos.
    if (data.hasCompletedToday) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Treino extra', style: AppTypography.h3),
          content: Text(
            'Você já ganhou seus pontos hoje. Este treino não contará pontos.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar treino'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isStarting = true);
    try {
      await WorkoutApiService().startWorkout();

      if (!mounted) return;

      _pushWorkoutStep();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Widget _buildResumeBanner() {
    return GestureDetector(
      onTap: _pushWorkoutStep,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treino em andamento',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'Toque para continuar de onde parou.',
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
              color: AppColors.warning.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acesso Rápido', style: AppTypography.h3),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              context,
              icon: Icons.history,
              label: 'Histórico',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.person_outline,
              label: 'Personais',
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(context, '/personals'),
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.show_chart,
              label: 'Progresso',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/progress'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECK-IN BUTTON WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  final bool hasCheckedInToday;
  final bool hasCompletedToday;
  final VoidCallback? onTap;

  const _CheckInButton({
    required this.hasCheckedInToday,
    required this.hasCompletedToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool done = hasCompletedToday;

    final String title = hasCompletedToday
        ? 'Treino concluído hoje'
        : hasCheckedInToday
        ? 'Check-in realizado!'
        : 'Faça check-in na academia';

    final String subtitle = hasCompletedToday
        ? 'Continue treinando para manter seu streak semanal'
        : hasCheckedInToday
        ? 'Você já pode iniciar seu treino.'
        : 'para iniciar seu treino';

    final Color color = done ? AppColors.accent : AppColors.primary;

    final IconData icon = hasCompletedToday
        ? Icons.emoji_events_rounded
        : hasCheckedInToday
        ? Icons.check_circle_rounded
        : Icons.fitness_center_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: done
            ? AppColors.accent.withValues(alpha: 0.10)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.accent.withValues(alpha: 0.30)
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
