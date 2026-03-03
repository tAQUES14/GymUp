import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_card.dart';
import '../models/workout_model.dart';
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
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Exercise Image/Icon placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
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

                  // Expand Icon
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

          // Expanded Content
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
                const SizedBox(height: 16),
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
