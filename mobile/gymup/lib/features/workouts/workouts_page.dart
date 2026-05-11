import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../home/widgets/daily_workout_card.dart';
import 'models/workout_model.dart';
import 'models/workout_plan_model.dart';
import 'workout_api_service.dart';
import 'workout_plan_api_service.dart';
import 'workout_plan_utils.dart';

const _kBlue  = Color(0xFF2563EB);

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  List<WorkoutModel> _workouts = [];
  TodayWorkoutPlan?  _todayPlan;
  bool _isLoading = true;
  bool _hasError  = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final results = await Future.wait([
        WorkoutApiService().getWorkouts(),
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
      ]);

      if (!mounted) return;
      setState(() {
        _workouts   = results[0] as List<WorkoutModel>;
        _todayPlan  = results[1] as TodayWorkoutPlan?;
        _isLoading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const GymUpLoading()
          : _hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── Conteúdo ─────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _kBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── SEÇÃO 1: Treino de hoje (plano ou fallback) ────────────────
            _buildTodaySection(),

            const SizedBox(height: 28),

            // ── SEÇÃO 2: Outros treinos disponíveis ───────────────────────
            _buildOtherWorkoutsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    if (_todayPlan == null) {
      // Sem plano: mostrar primeiro treino avulso como destaque
      final first = _workouts.isNotEmpty ? _workouts.first : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DailyWorkoutCard(
            workoutName: first?.name ?? 'Nenhum treino cadastrado',
            duration: first != null ? '${first.duration ?? 0} min' : '--',
            level:    first?.level ?? '--',
            onTap: first != null
                ? () => Navigator.pushNamed(context, '/workout-detail', arguments: first)
                : null,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card do plano (treino ou descanso)
        if (_todayPlan!.isRestDay)
          _RestDayCard(plan: _todayPlan!)
        else
          _PlanWorkoutCard(
            plan: _todayPlan!,
            onStart: () => _startPlanWorkout(_todayPlan!),
          ),
        const SizedBox(height: 16),

        // Visão semanal do plano
        _DaySequenceStrip(plan: _todayPlan!),
      ],
    );
  }

  Widget _buildOtherWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _todayPlan != null ? 'Outros treinos' : 'Meus Treinos',
              style: AppTypography.h3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                if (_workouts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_workouts.length}',
                      style: AppTypography.caption.copyWith(
                        color: _kBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/workout-generated')
                      .then((_) => _loadAll()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Criar',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_workouts.isEmpty)
          _buildEmpty()
        else
          ..._workouts.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WorkoutCard(
              workout: w,
              onTap: () => Navigator.pushNamed(
                context,
                '/workout-detail',
                arguments: w,
              ),
            ),
          )),
      ],
    );
  }

  void _startPlanWorkout(TodayWorkoutPlan plan) {
    Navigator.pushNamed(context, '/workout-detail', arguments: workoutFromPlan(plan));
  }

  // ── Estado vazio ─────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, color: _kBlue, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não tem outros treinos',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie um treino personalizado para complementar seu plano.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/workout-generated')
                  .then((_) => _loadAll()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Criar meu treino'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado de erro ────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
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
              'Não foi possível carregar os treinos.\nVerifique sua conexão.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadAll,
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
    );
  }
}

// ─── Card de descanso ─────────────────────────────────────────────────────────

class _RestDayCard extends StatelessWidget {
  final TodayWorkoutPlan plan;

  const _RestDayCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  plan.planName,
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

// ─── Card do plano de treino ──────────────────────────────────────────────────

class _PlanWorkoutCard extends StatelessWidget {
  final TodayWorkoutPlan plan;
  final VoidCallback onStart;

  const _PlanWorkoutCard({required this.plan, required this.onStart});

  static String _dowLabel(int dow) {
    const labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return labels[dow.clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final exercises     = plan.today.exercises;
    final strengthCount = exercises.where((e) => !e.isCardio).length;
    final cardioCount   = exercises.where((e) => e.isCardio).length;
    final hasSuperset   = exercises.any((e) => e.isSuperset);
    final hasDropset    = exercises.any((e) => e.isDropset);
    final hasCircuit    = exercises.any((e) => e.isCircuit);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rótulo do dia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 11),
                const SizedBox(width: 5),
                Text(
                  'HOJE · ${_dowLabel(plan.today.dayOfWeek).toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Header row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.today.name,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.planName,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Exercise badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (strengthCount > 0)
                _ExerciseBadge(
                  icon: Icons.fitness_center_rounded,
                  label: '$strengthCount musculação',
                ),
              if (cardioCount > 0)
                _ExerciseBadge(
                  icon: Icons.directions_run_rounded,
                  label: '$cardioCount cardio',
                ),
              if (hasSuperset)
                _ExerciseBadge(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Superset',
                ),
              if (hasDropset)
                _ExerciseBadge(
                  icon: Icons.trending_down_rounded,
                  label: 'Dropset',
                ),
              if (hasCircuit)
                _ExerciseBadge(
                  icon: Icons.loop_rounded,
                  label: 'Circuito',
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Lista de exercícios (até 5, resto resumido)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              children: [
                ...exercises.take(5).map((e) {
                  final detail = e.isCardio
                      ? '${e.durationMinutes ?? '--'} min'
                      : '${e.sets ?? '--'}x${e.reps ?? '--'}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          e.isCardio
                              ? Icons.directions_run_rounded
                              : Icons.fitness_center_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.name,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          detail,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (exercises.length > 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${exercises.length - 5} exercício${exercises.length - 5 == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Iniciar Treino'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kBlue,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card de treino ───────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const _WorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final exerciseCount = workout.exercises.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [

            // Ícone com fundo azul suave
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: _kBlue,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Nome + chips de info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniTag(
                        icon: Icons.bar_chart_rounded,
                        label: workout.level ?? '--',
                      ),
                      const SizedBox(width: 8),
                      _MiniTag(
                        icon: Icons.timer_outlined,
                        label: '${workout.duration ?? 0} min',
                      ),
                      if (exerciseCount > 0) ...[
                        const SizedBox(width: 8),
                        _MiniTag(
                          icon: Icons.layers_rounded,
                          label: '$exerciseCount ex.',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Visão semanal do plano ────────────────────────────────────────────────────
//
// Mostra os 7 dias da semana (Seg→Dom) com base no weekOverview do plano.
// Dias de treino do plano têm borda azul; dias de descanso têm ícone de lua.
// O dia de hoje é destacado.
class _DaySequenceStrip extends StatelessWidget {
  final TodayWorkoutPlan plan;

  const _DaySequenceStrip({required this.plan});

  // Exibição Seg→Dom: dow 1,2,3,4,5,6,0
  static const _displayOrder = [1, 2, 3, 4, 5, 6, 0];
  static const _labels       = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final todayDow = DateTime.now().weekday % 7; // Dart Mon=1..Sun=7 → Sun=0..Sat=6

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu progresso na semana',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (i) {
                final dow       = _displayOrder[i];
                final summary   = plan.weekOverview[dow];
                final isToday   = dow == todayDow;
                final isRest    = summary?.restDay ?? true;
                final hasWorkout = summary?.hasWorkout ?? false;
                final label     = summary?.name ?? _labels[i];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DayChip(
                    dayNumber: i + 1,
                    isCurrent: isToday,
                    isPast:    false,
                    label:     label,
                    isRestDay: isRest,
                    hasWorkout: hasWorkout,
                    shortLabel: _labels[i],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int    dayNumber;
  final bool   isCurrent;
  final bool   isPast;
  final String label;
  final bool   isRestDay;
  final bool   hasWorkout;
  final String shortLabel;

  const _DayChip({
    required this.dayNumber,
    required this.isCurrent,
    required this.isPast,
    required this.label,
    required this.isRestDay,
    this.hasWorkout = false,
    this.shortLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isCurrent
        ? _kBlue
        : hasWorkout && !isRestDay
            ? _kBlue.withValues(alpha: 0.08)
            : Colors.white;

    final Color border = isCurrent
        ? _kBlue
        : hasWorkout && !isRestDay
            ? _kBlue.withValues(alpha: 0.30)
            : const Color(0xFFE2E8F0);

    final Color textColor = isCurrent
        ? Colors.white
        : hasWorkout && !isRestDay
            ? _kBlue
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRestDay)
            Icon(Icons.bedtime_rounded, size: 12, color: textColor)
          else
            Icon(Icons.fitness_center_rounded, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            shortLabel.isNotEmpty ? shortLabel : (label.length > 10 ? '${label.substring(0, 9)}…' : label),
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Badge para o card do plano de treino
class _ExerciseBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExerciseBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Chip de info minimalista
class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
