import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../home/widgets/daily_workout_card.dart';
import 'models/workout_model.dart';
import 'models/workout_plan_model.dart';
import 'workout_api_service.dart';
import 'workout_plan_api_service.dart';

const _kBlue  = Color(0xFF2563EB);
const _kSlate = Color(0xFF64748B);

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
    final first = _workouts.isNotEmpty ? _workouts.first : null;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _kBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Plano ativo ────────────────────────────────────────────────
            if (_todayPlan != null) ...[
              if (_todayPlan!.isRestDay)
                _RestDayCard(plan: _todayPlan!)
              else
                _PlanWorkoutCard(
                  plan: _todayPlan!,
                  onStart: () => _startPlanWorkout(_todayPlan!),
                ),
              const SizedBox(height: 16),

              // Sequência visual dos dias do plano
              _DaySequenceStrip(plan: _todayPlan!),
            ],

            // ── Sem plano: fallback com treinos avulsos ─────────────────────
            if (_todayPlan == null) ...[
              DailyWorkoutCard(
                workoutName: first?.name ?? 'Nenhum treino cadastrado',
                duration: first != null ? '${first.duration ?? 0} min' : '--',
                level:    first?.level ?? '--',
                onTap: first != null
                    ? () => Navigator.pushNamed(context, '/workout-detail', arguments: first)
                    : null,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meus Treinos',
                    style: AppTypography.h3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }

  void _startPlanWorkout(TodayWorkoutPlan plan) {
    final day = plan.currentDay;

    // Convert WorkoutPlanExerciseModel → ExerciseModel
    final exercises = day.exercises.map((pe) {
      // Parse reps as int: "10-12" → 10, "30s" → 30, "12" → 12
      // For cardio, use durationMinutes as reps proxy for the existing session UI
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

    final workout = WorkoutModel(
      id:                          plan.planId * 1000 + plan.currentDayIndex,
      name:                        day.name,
      description:                 '${plan.planName} — Dia ${plan.currentDayIndex} de ${plan.totalDays}',
      exercises:                   exercises,
      betweenExerciseRestSeconds:  plan.betweenExerciseRestSeconds,
    );

    Navigator.pushNamed(context, '/workout-detail', arguments: workout);
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
            'Nenhum treino ainda',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Peça ao seu personal para criar\num treino personalizado.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
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

// ─── Card do plano de treino ──────────────────────────────────────────────────

class _PlanWorkoutCard extends StatelessWidget {
  final TodayWorkoutPlan plan;
  final VoidCallback onStart;

  const _PlanWorkoutCard({required this.plan, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final exercises     = plan.currentDay.exercises;
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
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.currentDay.name,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dia ${plan.currentDayIndex} de ${plan.totalDays} · ${plan.planName}',
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

// ─── Tira de sequência de dias ─────────────────────────────────────────────────
//
// Mostra todos os dias do plano em ordem, destacando o dia atual.
// Dias de descanso têm ícone de lua. O dia ativo tem borda azul.
//
// A API retorna currentDay + totalDays mas não a lista completa de dias.
// Para não fazer um request extra, mostramos chips numerados com o nome
// abreviado e indicamos qual é o dia ativo.
class _DaySequenceStrip extends StatelessWidget {
  final TodayWorkoutPlan plan;

  const _DaySequenceStrip({required this.plan});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Text(
                'Sequência do plano',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Dia ${plan.currentDayIndex} de ${plan.totalDays}',
                style: AppTypography.caption.copyWith(
                  color: _kBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(plan.totalDays, (i) {
                final dayNumber = i + 1;
                final isCurrent = dayNumber == plan.currentDayIndex;
                final isPast    = dayNumber < plan.currentDayIndex;

                // Use allDays metadata when available for real names/rest flags
                final summary = (i < plan.allDays.length) ? plan.allDays[i] : null;
                final label   = summary?.name ?? (isCurrent ? plan.currentDay.name : 'Dia $dayNumber');
                final isRest  = summary?.restDay ?? (isCurrent && plan.isRestDay);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DayChip(
                    dayNumber: dayNumber,
                    isCurrent: isCurrent,
                    isPast:    isPast,
                    label:     label,
                    isRestDay: isRest,
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

  const _DayChip({
    required this.dayNumber,
    required this.isCurrent,
    required this.isPast,
    required this.label,
    required this.isRestDay,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isCurrent
        ? _kBlue
        : isPast
            ? const Color(0xFFE2E8F0)
            : Colors.white;

    final Color border = isCurrent
        ? _kBlue
        : const Color(0xFFE2E8F0);

    final Color textColor = isCurrent
        ? Colors.white
        : isPast
            ? _kSlate
            : AppColors.textPrimary;

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
            Text(
              '$dayNumber',
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            // Abbreviate long names to fit
            label.length > 10 ? '${label.substring(0, 9)}…' : label,
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
