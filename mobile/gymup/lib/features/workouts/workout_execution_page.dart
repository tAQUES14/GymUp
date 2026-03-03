import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gymup_app_bar.dart';
import 'controllers/workout_execution_controller.dart';
import 'models/workout_model.dart';
import 'widgets/execution_exercise_card.dart';
import 'widgets/rest_timer_sheet.dart';

class WorkoutExecutionPage extends StatefulWidget {
  const WorkoutExecutionPage({super.key});

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  WorkoutExecutionController? _controller;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is WorkoutModel) {
        _controller = WorkoutExecutionController(workout: args);
        debugPrint(
          '[ExecutionPage] controller CRIADO '
          '(hashCode=${_controller.hashCode}) workout=${args.id}',
        );
        // Load all weights in parallel — controller notifies listeners when done
        _controller!.loadAllWeights();
      }
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showRestTimer(int duration) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RestTimerSheet(
        initialDuration: duration > 0 ? duration : 60,
        onTimerComplete: () {},
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

    if (_controller == null) {
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

    // Provide the controller to the entire subtree so SetsTable can access it.
    return ChangeNotifierProvider<WorkoutExecutionController>.value(
      value: _controller!,
      child: Consumer<WorkoutExecutionController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: GymUpAppBar(title: ctrl.workout.name),
            body: Column(
              children: [
                // Progress bar: exercises completed / total exercises
                LinearProgressIndicator(
                  value: ctrl.progress,
                  backgroundColor: AppColors.surface,
                  color: AppColors.primary,
                  minHeight: 6,
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ctrl.workout.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = ctrl.workout.exercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ExecutionExerciseCard(
                          exercise: exercise,
                          exerciseId: exercise.id,
                          isInitiallyExpanded: index == 0,
                          onSetCompleted: () =>
                              _showRestTimer(exercise.rest),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
