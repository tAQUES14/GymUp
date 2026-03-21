import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../challenges/challenge_api_service.dart';
import '../challenges/challenge_details_page.dart';
import '../goals/goal_api_service.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/models/workout_plan_model.dart';
import '../workouts/workout_api_service.dart';
import '../workouts/workout_plan_api_service.dart';
import 'widgets/active_challenge_card.dart';
import 'widgets/home_header.dart';
import 'widgets/daily_streak_card.dart';
import 'widgets/weekly_goal_section.dart';
import 'widgets/daily_workout_card.dart';
import 'widgets/weekly_progress_bar.dart';
import 'widgets/recent_activities_list.dart';

const _kBlue = Color(0xFF2563EB);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DashboardData?    _dashboardData;
  GoalData?         _goalData;
  ChallengeData?    _challengeData;
  TodayWorkoutPlan? _todayPlan;
  WorkoutModel?     _todayWorkout;

  bool _isLoading  = true;
  bool _hasError   = false;
  bool _isStarting = false;

  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final seq = ++_loadSeq;

    setState(() { _isLoading = true; _hasError = false; });

    try {
      final api     = WorkoutApiService();
      final results = await Future.wait<dynamic>([
        api.getDashboard(),
        api.getWorkouts(),
        GoalApiService().getCurrentGoal().catchError((_) => null),
        ChallengeApiService().getActiveChallenge().catchError((_) => null),
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
      ]);

      if (!mounted || seq != _loadSeq) return;

      final data     = results[0] as DashboardData;
      final workouts = results[1] as List<WorkoutModel>;
      final plan     = results[4] as TodayWorkoutPlan?;

      setState(() {
        _dashboardData = data;
        _todayPlan     = plan;
        // Source of truth: use plan when available; fall back to loose workout.
        if (plan != null && !plan.isRestDay) {
          _todayWorkout = _workoutFromPlan(plan);
        } else if (plan == null) {
          _todayWorkout = workouts.isNotEmpty ? workouts.first : null;
        } else {
          _todayWorkout = null; // rest day — no executable workout
        }
        _goalData      = results[2] as GoalData?;
        _challengeData = results[3] as ChallengeData?;
        _isLoading     = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;

      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  // Converts a plan day into the WorkoutModel used by the existing session UI.
  // Mirrors the same logic in WorkoutsPage._startPlanWorkout.
  WorkoutModel _workoutFromPlan(TodayWorkoutPlan plan) {
    final exercises = plan.currentDay.exercises.map((pe) {
      int parsedReps = 10;
      if (pe.isCardio) {
        parsedReps = pe.durationMinutes ?? 10;
      } else if (pe.reps != null) {
        final repsStr = pe.reps!.replaceAll(RegExp(r'[^0-9]'), '');
        if (repsStr.isNotEmpty) parsedReps = int.tryParse(repsStr) ?? 10;
      }
      return ExerciseModel(
        id:          pe.exerciseId,
        name:        pe.name,
        muscleGroup: pe.muscleGroup,
        gifUrl:      pe.gifUrl,
        defaultRest: pe.defaultRest,
        sets:        pe.sets ?? 1,
        reps:        parsedReps,
        rest:        pe.isCardio ? 0 : pe.restSeconds,
      );
    }).toList();

    return WorkoutModel(
      id:                         plan.planId * 1000 + plan.currentDayIndex,
      name:                       plan.currentDay.name,
      description:                '${plan.planName} — Dia ${plan.currentDayIndex} de ${plan.totalDays}',
      exercises:                  exercises,
      betweenExerciseRestSeconds: plan.betweenExerciseRestSeconds,
    );
  }

  void _pushWorkoutStep() {
    if (_todayWorkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum treino cadastrado. Crie um treino na aba Treinos.'),
        ),
      );
      return;
    }

    assert(_todayWorkout!.id > 0, 'BUG: workout com ID inválido chegou à navegação.');

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
      return _buildError();
    }

    final data = _dashboardData!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: _kBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Saudação ─────────────────────────────────────────────────
              HomeHeader(
                nome: data.name,
                points: data.pointsBalance,
              ),

              const SizedBox(height: 24),

              // ── Streak diário ─────────────────────────────────────────────
              DailyStreakCard(
                streak: data.streak,
                bestStreak: data.bestStreak,
                trainingDays: data.trainingDays,
              ),

              const SizedBox(height: 16),

              // ── Meta semanal (volume semanal) ─────────────────────────────
              WeeklyGoalCard(
                workoutsDone: data.weeklyProgress.where((d) => d).length,
                weeklyGoal: data.weeklyGoal,
              ),

              const SizedBox(height: 24),

              // ── Treino do dia (HERO) ──────────────────────────────────────
              _buildTodayHero(),

              // ── Treino em andamento ───────────────────────────────────────
              if (data.hasActiveSession) ...[
                const SizedBox(height: 12),
                _buildResumeBanner(),
              ],

              // ── Check-in ──────────────────────────────────────────────────
              if (!data.hasActiveSession && !data.hasCompletedToday) ...[
                const SizedBox(height: 12),
                _CheckInStatus(
                  hasCheckedInToday: data.hasCheckedInToday,
                  onTap: _handleStartWorkout,
                ),
              ],

              const SizedBox(height: 28),

              // ── Progresso semanal ─────────────────────────────────────────
              WeeklyProgressBar(weeklyProgress: data.weeklyProgress),

              const SizedBox(height: 28),

              // ── Meta pessoal ──────────────────────────────────────────────
              _buildGoalCard(),

              const SizedBox(height: 28),

              // ── Desafio da academia ───────────────────────────────────────
              if (_challengeData != null) ...[
                ActiveChallengeCard(
                  challenge: _challengeData!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailsPage(challenge: _challengeData!),
                    ),
                  ).then((_) => _loadDashboard()),
                ),
                const SizedBox(height: 28),
              ],

              // ── Acesso rápido ─────────────────────────────────────────────
              _buildSectionTitle('Acesso rápido'),
              const SizedBox(height: 12),
              _buildQuickActions(context),

              const SizedBox(height: 28),

              // ── Atividades recentes ───────────────────────────────────────
              _buildSectionTitle('Atividades recentes'),
              const SizedBox(height: 12),
              RecentActivitiesList(activities: data.recentActivities),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  Widget _buildTodayHero() {
    // Rest day from active plan
    if (_todayPlan != null && _todayPlan!.isRestDay) {
      return _RestDayHeroCard(plan: _todayPlan!);
    }

    // Workout day from active plan
    if (_todayPlan != null) {
      return DailyWorkoutCard(
        workoutName: _todayPlan!.currentDay.name,
        duration:    'Dia ${_todayPlan!.currentDayIndex} de ${_todayPlan!.totalDays}',
        level:       _todayPlan!.planName,
        onTap:       _isStarting ? null : _handleStartWorkout,
      );
    }

    // No plan: fall back to first loose workout
    return DailyWorkoutCard(
      workoutName: _todayWorkout?.name ?? 'Nenhum treino cadastrado',
      duration:    _todayWorkout != null ? '${_todayWorkout!.duration ?? 0} min' : '--',
      level:       _todayWorkout?.level ?? '--',
      onTap:       _isStarting ? null : _handleStartWorkout,
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    const actions = [
      (icon: Icons.bar_chart_rounded,       label: 'Progresso', route: '/progress'),
      (icon: Icons.emoji_events_rounded,    label: 'Desafios',  route: '/challenges'),
      (icon: Icons.history_rounded,         label: 'Histórico', route: '/history'),
      (icon: Icons.person_outline_rounded,  label: 'Personais', route: '/personals'),
    ];

    return Column(
      children: [
        Row(
          children: [
            _quickActionCard(context, actions[0]),
            const SizedBox(width: 12),
            _quickActionCard(context, actions[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickActionCard(context, actions[2]),
            const SizedBox(width: 12),
            _quickActionCard(context, actions[3]),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    ({IconData icon, String label, String route}) action,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, action.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: _kBlue, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
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
                child: Icon(Icons.wifi_off_rounded, size: 34, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text('Sem conexão', style: AppTypography.h3),
              const SizedBox(height: 8),
              Text(
                'Não foi possível carregar seus dados.\nVerifique sua conexão.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card de Meta ──────────────────────────────────────────────────────────

  Widget _buildGoalCard() {
    if (_goalData == null) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/goals/create').then((_) => _loadDashboard()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: _kBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Defina sua meta',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Acompanhe sua evolução com uma meta pessoal.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    }

    final goal    = _goalData!;
    final deltaKg = (goal.targetWeight - goal.startWeight).abs();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/goals').then((_) => _loadDashboard()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.goalTypeLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${goal.startWeight.toStringAsFixed(1)} → ${goal.targetWeight.toStringAsFixed(1)} kg  (${deltaKg.toStringAsFixed(1)} kg)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ── Banner "Retomar treino" ───────────────────────────────────────────────

  Widget _buildResumeBanner() {
    return GestureDetector(
      onTap: _pushWorkoutStep,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
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
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
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
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.warning.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleStartWorkout() async {
    if (_isStarting) return;
    final data = _dashboardData!;

    if (data.hasActiveSession) {
      _pushWorkoutStep();
      return;
    }

    if (!data.hasCheckedInToday && !data.hasCompletedToday) {
      Navigator.of(context).pushNamed('/checkin').then((_) => _loadDashboard());
      return;
    }

    if (data.hasCompletedToday) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Treino extra', style: AppTypography.h3),
          content: Text(
            'Você já ganhou seus pontos hoje. Este treino não contará pontos.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO: DIA DE DESCANSO
// ─────────────────────────────────────────────────────────────────────────────

class _RestDayHeroCard extends StatelessWidget {
  final TodayWorkoutPlan plan;
  const _RestDayHeroCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoje é dia de descanso',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.planName} · Dia ${plan.currentDayIndex} de ${plan.totalDays}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
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

// ─────────────────────────────────────────────────────────────────────────────
// STATUS DE CHECK-IN (banner sutil, não bloqueia UI)
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInStatus extends StatelessWidget {
  final bool hasCheckedInToday;
  final VoidCallback? onTap;

  const _CheckInStatus({
    required this.hasCheckedInToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hasCheckedInToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              'Check-in realizado — você já pode iniciar o treino.',
              style: AppTypography.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBlue.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _kBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Faça check-in na academia antes de iniciar.',
                style: AppTypography.caption.copyWith(
                  color: _kBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kBlue, size: 18),
          ],
        ),
      ),
    );
  }
}
