import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'widgets/exercise_image_widget.dart';
import 'workout_api_service.dart';

const _kBlue      = Color(0xFF2563EB);
const _kBlueDark  = Color(0xFF1D4ED8);

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class WorkoutDetailPage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  bool _isStarting = false;

  // ── Lógica de início (inalterada) ──────────────────────────

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

    if (data.hasActiveSession) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Treino em andamento', style: AppTypography.h3),
          content: Text(
            'Você tem um treino em andamento. Deseja continuar ou iniciar outro?',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: Text(
                'Iniciar novo',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (!mounted) { setState(() => _isStarting = false); return; }

      if (choice == 'continue') {
        Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
      } else if (choice == 'new') {
        try {
          await WorkoutApiService().finishWorkout(
            completionPercent: 0,
            durationSeconds: 0,
            confirmPartial: true,
          );
          if (!mounted) { setState(() => _isStarting = false); return; }
          await WorkoutApiService().startWorkout();
          if (!mounted) { setState(() => _isStarting = false); return; }
          Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
        } catch (e) {
          if (!mounted) { setState(() => _isStarting = false); return; }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }

      setState(() => _isStarting = false);
      return;
    }

    if (!data.hasCheckedInToday) {
      Navigator.pushNamed(context, '/checkin', arguments: widget.workout);
      setState(() => _isStarting = false);
      return;
    }

    if (data.hasCompletedToday) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Você já treinou hoje', style: AppTypography.h3),
          content: Text(
            'Este treino não contará pontos.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero expandido: nome + stats do treino ─────────
          _HeroAppBar(workout: workout),

          // ── Título da lista de exercícios ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Exercícios',
                    style: AppTypography.h3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${workout.exercises.length}',
                      style: AppTypography.caption.copyWith(
                        color: _kBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de exercícios ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            sliver: SliverList.separated(
              itemCount: workout.exercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ExerciseCard(
                exercise: workout.exercises[i],
                index: i + 1,
              ),
            ),
          ),

          // Espaço para o botão não sobrepor o último item
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _StartBar(
        isLoading: _isStarting,
        onPressed: _handleStartWorkout,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero AppBar — expande mostrando nome e stats, colapsa limpamente
// ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final WorkoutModel workout;

  const _HeroAppBar({required this.workout});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: _kBlue,
      surfaceTintColor: _kBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Título compacto — aparece ao colapsar
      title: Text(
        workout.name,
        style: AppTypography.h3.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeroBanner(workout: workout),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Banner — conteúdo do estado expandido
// ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final WorkoutModel workout;

  const _HeroBanner({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlueDark],
        ),
      ),
      // Padding top: altura do AppBar (~56) + safe area
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Nome do treino — destaque máximo
          Text(
            workout.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (workout.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              workout.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Stats: duração · nível · exercícios
          Row(
            children: [
              _HeroStat(
                icon: Icons.access_time_rounded,
                value: '${workout.duration ?? 0} min',
              ),
              _heroDot(),
              _HeroStat(
                icon: Icons.bar_chart_rounded,
                value: workout.level ?? '--',
              ),
              _heroDot(),
              _HeroStat(
                icon: Icons.layers_rounded,
                value: '${workout.exercises.length} ex.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroDot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.40),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String   value;

  const _HeroStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.90),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Exercise Card — painel esquerdo azul + conteúdo
// ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int           index;

  const _ExerciseCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    final cargaText = exercise.carga > 0
        ? '${exercise.carga.toStringAsFixed(0)} kg'
        : 'Livre';
    final statsLine =
        '${exercise.sets}×${exercise.reps}  •  $cargaText  •  ${exercise.rest}s';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Imagem com badge de número ────────────────────
          Stack(
            children: [
              ExerciseImageWidget(exercise: exercise, size: 64),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // ── Conteúdo principal ────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Nome
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Grupo muscular
                Text(
                  exercise.muscleGroup,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 7),

                // Stats compactas: 3×12 • Livre • 60s
                Text(
                  statsLine,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Start Bar — CTA fixo no rodapé (thumb zone)
// ─────────────────────────────────────────────────────────────

class _StartBar extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onPressed;

  const _StartBar({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : const LinearGradient(
                        colors: [_kBlue, _kBlueDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                          const Icon(Icons.play_arrow_rounded,
                              size: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'INICIAR TREINO',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

