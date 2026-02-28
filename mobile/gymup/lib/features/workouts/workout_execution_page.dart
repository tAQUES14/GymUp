import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gymup_app_bar.dart';
import 'models/workout_model.dart';
import 'widgets/execution_exercise_card.dart';
import 'widgets/rest_timer_sheet.dart';

class WorkoutExecutionPage extends StatefulWidget {
  const WorkoutExecutionPage({super.key});

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  WorkoutModel? _workout;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_workout == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is WorkoutModel) {
        _workout = args;
      }
      _isLoading = false;
    }
  }

  double get _progress {
    if (_workout == null) return 0.0;
    int totalSets = 0;
    int completedSets = 0;

    for (var exercise in _workout!.exercises) {
      totalSets += exercise.sets;
      completedSets += exercise.workoutSets.where((s) => s.isCompleted).length;
    }

    if (totalSets == 0) return 0.0;
    return completedSets / totalSets;
  }

  void _onSetCompleted(ExerciseModel exercise, int setIndex, bool isCompleted) {
    setState(() {
      exercise.workoutSets[setIndex].isCompleted = isCompleted;
    });

    if (isCompleted) {
      _showRestTimer(exercise.rest);
    }
  }

  void _showRestTimer(int duration) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RestTimerSheet(
        initialDuration: duration > 0 ? duration : 60,
        onTimerComplete: () {
          // Could enable haptic feedback here
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_workout == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Treino não encontrado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GymUpAppBar(title: _workout!.name),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.surface,
            color: AppColors.primary, // Neon Green / Electric Blue
            minHeight: 6,
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workout!.exercises.length,
              itemBuilder: (context, index) {
                final exercise = _workout!.exercises[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExecutionExerciseCard(
                    exercise: exercise,
                    isInitiallyExpanded:
                        index == 0, // First expanded by default
                    onSetCompleted: (setIndex, isCompleted) =>
                        _onSetCompleted(exercise, setIndex, isCompleted),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
