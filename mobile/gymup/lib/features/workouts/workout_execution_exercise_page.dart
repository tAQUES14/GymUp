import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'workout_complete_page.dart';
import '../services/workout_execution_service.dart';

class WorkoutExecutionExercisePage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutExecutionExercisePage({super.key, required this.workout});

  @override
  State<WorkoutExecutionExercisePage> createState() =>
      _WorkoutExecutionExercisePageState();
}

class _WorkoutExecutionExercisePageState
    extends State<WorkoutExecutionExercisePage> {
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;

  Timer? _workoutTimer;
  final ValueNotifier<Duration> _elapsedTime =
      ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _elapsedTime.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedTime.value =
          _elapsedTime.value + const Duration(seconds: 1);
    });
  }

  ExerciseModel get _currentExercise =>
      widget.workout.exercises[_currentExerciseIndex];

  WorkoutSet get _currentSet =>
      _currentExercise.workoutSets[_currentSetIndex];

  int get _totalExercises =>
      widget.workout.exercises.length;

  int get _totalSets => _currentExercise.sets;

  int get _totalSetsConcluidos {
    int total = 0;
    for (final ex in widget.workout.exercises) {
      total += ex.workoutSets.where((s) => s.isCompleted).length;
    }
    return total;
  }

  int get _totalSetsGlobal {
    int total = 0;
    for (final ex in widget.workout.exercises) {
      total += ex.sets;
    }
    return total;
  }

  void _onMarkDonePressed() {
    HapticFeedback.lightImpact();

    setState(() {
      _currentSet.isCompleted = true;
    });

    if (_currentSetIndex < _totalSets - 1) {
      _currentSetIndex++;
    } else if (_currentExerciseIndex < _totalExercises - 1) {
      _currentExerciseIndex++;
      _currentSetIndex = 0;
    } else {
      _finishWorkout();
    }
  }

  Future<void> _finishWorkout() async {
    final service = WorkoutExecutionService();

    final duracaoMinutos =
        _elapsedTime.value.inMinutes;
    final concluidos = _totalSetsConcluidos;
    final total = _totalSetsGlobal;

    try {
      final result = await service.finishWorkout(
        workoutId: widget.workout.id,
        durationMinutes: duracaoMinutos,
        setsCompleted: concluidos,
        setsTotal: total,
      );

      final streak = result['streak'] ?? 1;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutCompletePage(
            workoutNome: widget.workout.name,
            duracaoMinutos: duracaoMinutos,
            setsConcluidos: concluidos,
            setsTotais: total,
            streak: streak,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Execução',
          style:
              AppTypography.h3.copyWith(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ValueListenableBuilder<Duration>(
              valueListenable: _elapsedTime,
              builder: (_, d, _) {
                return Text(
                  '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              _currentExercise.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Reps: ${_currentSet.reps} | Carga: ${_currentSet.weight}',
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _onMarkDonePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'REALIZADO',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}