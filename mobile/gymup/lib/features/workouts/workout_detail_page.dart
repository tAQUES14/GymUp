import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'workout_api_service.dart';

class WorkoutDetailPage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleStartWorkout() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    DashboardData data;
    try {
      data = await WorkoutApiService().getDashboard();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _isStarting = false);
      return;
    }

    if (!mounted) return;

    // 1️⃣ Sessão ativa → retoma
    if (data.hasActiveSession) {
      Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
      setState(() => _isStarting = false);
      return;
    }

    // 2️⃣ Sem check-in → vai para QR, passando o treino selecionado
    if (!data.hasCheckedInToday) {
      Navigator.pushNamed(context, '/checkin', arguments: widget.workout);
      setState(() => _isStarting = false);
      return;
    }

    // 3️⃣ Já treinou hoje → aviso, não conta pontos
    if (data.hasCompletedToday) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Você já treinou hoje', style: AppTypography.h3),
          content: Text(
            'Este treino não contará pontos.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Treinar mesmo assim'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        setState(() => _isStarting = false);
        return;
      }

      Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
      setState(() => _isStarting = false);
      return;
    }

    // 4️⃣ Caso normal → cria sessão e inicia
    try {
      await WorkoutApiService().startWorkout();
      if (!mounted) return;
      Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(workout),
          SliverToBoxAdapter(child: _WorkoutHeader(workout: workout)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            sliver: SliverList.separated(
              itemCount: workout.exercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ExerciseCard(
                exercise: workout.exercises[i],
                index: i + 1,
              ),
            ),
          ),
          // Espaço para o botão do rodapé não sobrepor o último item
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: _StartBar(
        isLoading: _isStarting,
        onPressed: _handleStartWorkout,
      ),
    );
  }

  SliverAppBar _buildAppBar(WorkoutModel workout) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        workout.name,
        style: AppTypography.h3.copyWith(fontSize: 17),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        _DurationChip(duration: '${workout.duration ?? 0} min'),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Workout Header
// ─────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final WorkoutModel workout;

  const _WorkoutHeader({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BadgeChip(
                icon: Icons.bar_chart_rounded,
                label: workout.level ?? '',
                color: AppColors.primary,
              ),
              _BadgeChip(
                icon: Icons.fitness_center_rounded,
                label: '${workout.exercises.length} exercícios',
                color: AppColors.accent,
              ),
            ],
          ),
          if (workout.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(workout.description, style: AppTypography.bodyMedium),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Exercise Card
// ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int index;

  const _ExerciseCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    final setsCount = exercise.sets;
    final reps = exercise.reps;
    final carga = exercise.carga;
    final descanso = exercise.rest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho do exercício ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone do exercício
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Nome e descrição
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exercise.muscleGroup,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Número do exercício
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 12),

          // ── Mini-cards de stats ──
          Row(
            children: [
              _StatChip(
                value: '$setsCount',
                label: 'Séries',
                icon: Icons.layers_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: '$reps',
                label: 'Reps',
                icon: Icons.repeat_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: carga > 0 ? '${carga.toStringAsFixed(0)}kg' : 'Livre',
                label: 'Carga',
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: '${descanso}s',
                label: 'Descanso',
                icon: Icons.timer_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Start Bar (rodapé fixo com CTA)
// ─────────────────────────────────────────────────────────────

class _StartBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _StartBar({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 26),
                        const SizedBox(width: 8),
                        Text('INICIAR TREINO', style: AppTypography.button),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String duration;

  const _DurationChip({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            duration,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
