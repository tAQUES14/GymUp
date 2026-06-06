import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_typography.dart';
import 'exercise_detail_page.dart';
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
      final elapsedMin = data.activeSessionElapsedMinutes;
      final elapsedLabel = elapsedMin != null
          ? elapsedMin >= 60
              ? 'ha ${elapsedMin ~/ 60}h${elapsedMin % 60 > 0 ? ' ${elapsedMin % 60}min' : ''}'
              : 'ha $elapsedMin min'
          : null;

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Treino em andamento', style: AppTypography.h3),
          content: Text(
            elapsedLabel != null
                ? 'Voce tem um treino em andamento ($elapsedLabel). Deseja continuar ou iniciar outro?'
                : 'Voce tem um treino em andamento. Deseja continuar ou iniciar outro?',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: Text(
                'Iniciar novo',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (!mounted) {
        setState(() => _isStarting = false);
        return;
      }

      if (choice == 'continue') {
        Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
      } else if (choice == 'new') {
        try {
          await WorkoutApiService().finishWorkout(
            completionPercent: 0,
            durationSeconds: 0,
            confirmPartial: true,
          );
          if (!mounted) {
            setState(() => _isStarting = false);
            return;
          }
          await WorkoutApiService().startWorkout();
          if (!mounted) {
            setState(() => _isStarting = false);
            return;
          }
          Navigator.pushNamed(context, '/workout-step', arguments: widget.workout);
        } catch (e) {
          if (!mounted) {
            setState(() => _isStarting = false);
            return;
          }
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
          title: Text('Voce ja treinou hoje', style: AppTypography.h3),
          content: Text(
            'Este treino nao contara pontos.',
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
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: _WorkoutDetailHeader(workoutName: workout.name),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WorkoutHero(workout: workout),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: _ExercisesHeader(count: workout.exercises.length),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (var i = 0; i < workout.exercises.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ExerciseListCard(
                          exercise: workout.exercises[i],
                          index: i + 1,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 132),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StartWorkoutDock(
        isLoading: _isStarting,
        onTap: _handleStartWorkout,
      ),
    );
  }
}

class _WorkoutDetailHeader extends StatelessWidget {
  final String workoutName;

  const _WorkoutDetailHeader({required this.workoutName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            workoutName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.pjs(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          onTap: () {},
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 24,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.navBtn,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  final WorkoutModel workout;

  const _WorkoutHero({required this.workout});

  @override
  Widget build(BuildContext context) {
    final titleSize = _titleSize(workout.name);

    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.gradientWeekCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.weekCard,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -72,
            top: -62,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [Color(0x66C8F84A), Color(0x00C8F84A)],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(label: 'TREINO - ${_primaryMuscle(workout).toUpperCase()}'),
              const SizedBox(height: 18),
              Text(
                workout.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.pjs(
                  size: titleSize,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: titleSize >= 38 ? -1.4 : -0.9,
                ),
              ),
              const SizedBox(height: 12),
              _HeroMetaRow(
                items: [
                  _HeroMetaItem(Icons.schedule_rounded, '${workout.duration ?? 0} min'),
                  _HeroMetaItem(Icons.bar_chart_rounded, workout.level ?? 'Personalizado'),
                  _HeroMetaItem(Icons.list_rounded, '${workout.exercises.length} ex.'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _description(workout),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.pjs(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _primaryMuscle(WorkoutModel workout) {
    if (workout.exercises.isEmpty) return 'treino';
    final muscle = workout.exercises.first.muscleGroup.trim();
    return muscle.isEmpty ? 'treino' : muscle;
  }

  static String _description(WorkoutModel workout) {
    final description = workout.description.trim();
    if (description.isNotEmpty) return description;

    final muscle = _primaryMuscle(workout).toLowerCase();
    if (muscle == 'treino') return 'Treino personalizado para hoje.';
    return 'Treino focado em $muscle, forca e hipertrofia.';
  }

  static double _titleSize(String title) {
    final length = title.trim().length;
    if (length > 32) return 30;
    if (length > 24) return 33;
    if (length > 18) return 36;
    return 40;
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 10, color: AppColors.lime),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.pjs(
              size: 10,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaItem {
  final IconData icon;
  final String label;

  const _HeroMetaItem(this.icon, this.label);
}

class _HeroMetaRow extends StatelessWidget {
  final List<_HeroMetaItem> items;

  const _HeroMetaRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i].icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                items[i].label,
                style: AppText.pjs(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (i != items.length - 1)
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ],
    );
  }
}

class _ExercisesHeader extends StatelessWidget {
  final int count;

  const _ExercisesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Exercicios',
          style: AppText.pjs(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: AppText.sg(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseListCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int index;

  const _ExerciseListCard({
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseDetailPage(exercise: exercise),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blueDark,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: AppText.sg(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 22,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pjs(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _muscleLabel(exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pjs(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _ExerciseMetaRow(exercise: exercise),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }

  static String _muscleLabel(ExerciseModel exercise) {
    final muscle = exercise.muscleGroup.trim();
    return muscle.isEmpty ? 'EXERCICIO' : muscle.toUpperCase();
  }
}

class _ExerciseMetaRow extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExerciseMetaRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final items = [
      '${exercise.sets}x${exercise.reps}',
      'Livre',
      '${exercise.rest}s',
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Text(
            items[i],
            style: AppText.sg(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: -0.1,
            ),
          ),
          if (i != items.length - 1)
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.inkLight,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ],
    );
  }
}

class _StartWorkoutDock extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _StartWorkoutDock({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00F3F5F9),
            Color(0xD8F3F5F9),
            Color(0xFFF3F5F9),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimaryDark,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.buttonBlue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isLoading ? 'Iniciando...' : 'Iniciar treino',
                  textAlign: TextAlign.center,
                  style: AppText.pjs(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
