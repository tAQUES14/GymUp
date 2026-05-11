import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_card.dart';
import '../exercise_detail_page.dart';
import '../exercise_history_page.dart';
import '../models/workout_model.dart';
import 'exercise_image_widget.dart';
import 'sets_table.dart';

class ExecutionExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  final int exerciseId;
  final bool isInitiallyExpanded;

  /// Chamado quando uma série é concluída (ex.: para exibir rest timer).
  final VoidCallback? onSetCompleted;

  const ExecutionExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseId,
    this.isInitiallyExpanded = false,
    this.onSetCompleted,
  });

  @override
  State<ExecutionExerciseCard> createState() => _ExecutionExerciseCardState();
}

class _ExecutionExerciseCardState extends State<ExecutionExerciseCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return GymUpCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseDetailPage(exercise: widget.exercise),
                      ),
                    ),
                    child: ExerciseImageWidget(exercise: widget.exercise, size: 60),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.exercise.name, style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text(
                          widget.exercise.muscleGroup,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Colors.white12),
                SetsTable(
                  exerciseId: widget.exerciseId,
                  sets: widget.exercise.workoutSets,
                  onSetCompleted: widget.onSetCompleted,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailPage(exercise: widget.exercise),
                            ),
                          ),
                          icon: const Icon(Icons.play_circle_outline_rounded,
                              size: 18),
                          label: const Text('Ver execução'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseHistoryPage(exercise: widget.exercise),
                            ),
                          ),
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: const Text('Evolução'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
