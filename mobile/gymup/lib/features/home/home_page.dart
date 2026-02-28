import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../workouts/mocks/workouts_mock.dart';
import '../workouts/workout_api_service.dart';
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
  DashboardData? _dashboardData;
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

  Future<void> _loadDashboard() async {
    final seq = ++_loadSeq;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await WorkoutApiService().getDashboard();

      // Só aplica se ainda for a chamada mais recente e o widget estiver montado.
      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _dashboardData = data;
        _isLoading = false;
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
              const HomeHeader(nome: 'Aluno', photoUrl: null),
              const SizedBox(height: 24),

              PointsCard(pontos: data.pointsBalance),
              const SizedBox(height: 24),

              WeeklyGoalSection(
                streak: data.streak,
                workoutsDone: data.weeklyProgress.where((d) => d).length,
                weeklyGoal: 3,
              ),
              const SizedBox(height: 24),

              _CheckInButton(
                hasCheckedInToday: data.hasCheckedInToday,
                hasCompletedToday: data.hasCompletedToday,
                onTap: (data.hasCheckedInToday || data.hasCompletedToday)
                    ? null
                    : _handleStartWorkout,
              ),
              const SizedBox(height: 16),

              if (data.hasActiveSession) ...[
                _buildResumeBanner(),
                const SizedBox(height: 16),
              ],

              DailyWorkoutCard(onTap: _isStarting ? null : _handleStartWorkout),
              const SizedBox(height: 24),

              WeeklyProgressBar(weeklyProgress: data.weeklyProgress),
              const SizedBox(height: 24),

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

  Future<void> _handleStartWorkout() async {
    if (_isStarting) return;
    final data = _dashboardData!;

    if (data.hasActiveSession) {
      Navigator.of(context)
          .pushNamed(
            '/workout-step',
            arguments: WorkoutsMock.standardWorkouts[0],
          )
          .then((_) => _loadDashboard());
      return;
    }

    final bool alreadyHasSessionToday =
        data.hasActiveSession || data.hasCompletedToday;

    if (!alreadyHasSessionToday && !data.hasCheckedInToday) {
      Navigator.of(context)
          .pushNamed('/checkin')
          .then((_) => _loadDashboard());
      return;
    }

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

      Navigator.of(context)
          .pushNamed(
            '/workout-step',
            arguments: WorkoutsMock.standardWorkouts[0],
          )
          .then((_) => _loadDashboard());
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
      onTap: () => Navigator.pushNamed(
        context,
        '/workout-step',
        arguments: WorkoutsMock.standardWorkouts[0],
      ).then((_) => _loadDashboard()),
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
    final bool done = hasCheckedInToday || hasCompletedToday;

    final String title = hasCompletedToday
        ? 'Treino concluído hoje!'
        : hasCheckedInToday
        ? 'Check-in feito hoje!'
        : 'Fazer Check-in';

    final String subtitle = hasCompletedToday
        ? 'Parabéns! Você completou o treino de hoje.'
        : hasCheckedInToday
        ? 'Presença de hoje confirmada'
        : 'Escaneie o QR para iniciar o treino';

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
