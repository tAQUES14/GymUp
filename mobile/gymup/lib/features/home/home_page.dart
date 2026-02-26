import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../dashboard/dashboard_api_service.dart';
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
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;
  bool _hasError = false;
  WorkoutSessionData? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _checkActiveSession();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await DashboardApiService().getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
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

    if (_hasError || _dashboard == null) {
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

    final int pontos =
        (_dashboard!['points_balance'] as num?)?.toInt() ?? 0;
    final bool checkinFeito =
        _dashboard!['has_checked_in_today'] as bool? ?? false;
    final int streak = (_dashboard!['streak'] as num?)?.toInt() ?? 0;

    const String nome = 'Aluno';
    const String? photoUrl = null;
    const int workoutsDone = 0;
    const List<int> diasList = [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(nome: nome, photoUrl: photoUrl),
              const SizedBox(height: 24),

              PointsCard(pontos: pontos),
              const SizedBox(height: 24),

              WeeklyGoalSection(
                streak: streak,
                workoutsDone: workoutsDone,
                weeklyGoal: 3,
              ),
              const SizedBox(height: 24),

              // ── Botão de Check-in ─────────────────────────────────
              // Banner verde: apenas informativo (não clicável).
              // Banner padrão: navega para QR Code → inicia sessão de treino.
              _CheckInButton(
                done: checkinFeito,
                isLoading: false,
                onTap: checkinFeito
                    ? null
                    : () => Navigator.pushNamed(context, '/checkin'),
              ),
              const SizedBox(height: 16),

              if (_activeSession != null) ...[
                _buildResumeBanner(),
                const SizedBox(height: 16),
              ],

              DailyWorkoutCard(
                onTap: _onIniciarTreino,
              ),
              const SizedBox(height: 24),

              WeeklyProgressBar(diasTreinados: diasList),
              const SizedBox(height: 24),

              const RecentActivitiesList(),
              const SizedBox(height: 24),

              _buildQuickActions(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Session restore ───────────────────────────────────────────────────────

  Future<void> _checkActiveSession() async {
    try {
      final session = await WorkoutApiService().getStatus();
      if (mounted && session != null && session.isActive) {
        setState(() => _activeSession = session);
      }
    } catch (_) {}
  }

  // ── Lógica de navegação ───────────────────────────────────────────────────

  /// Verifica se há sessão ativa no backend:
  /// - Sessão ativa  → vai direto para a tela de treino.
  /// - Sem sessão    → vai para o QR Code para iniciar uma nova sessão.
  Future<void> _onIniciarTreino() async {
    try {
      final session = await WorkoutApiService().getStatus();
      if (!mounted) return;

      if (session != null && session.isActive) {
        Navigator.of(context).pushNamed(
          '/workout-step',
          arguments: WorkoutsMock.standardWorkouts[0],
        );
      } else {
        Navigator.of(context).pushNamed('/checkin');
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      // Em caso de erro, encaminha para o QR para tentar iniciar
      Navigator.of(context).pushNamed('/checkin');
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildResumeBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/workout-step',
        arguments: WorkoutsMock.standardWorkouts[0],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
          ),
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
  final bool done;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CheckInButton({
    required this.done,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: done ? AppColors.accent : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.fitness_center_rounded,
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
                        done ? 'Check-in feito hoje!' : 'Fazer Check-in',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: done ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      Text(
                        done
                            ? 'Presença de hoje confirmada'
                            : 'Escaneie o QR para iniciar o treino',
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
