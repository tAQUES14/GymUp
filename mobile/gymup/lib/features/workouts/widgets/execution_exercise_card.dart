import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_card.dart';
import '../exercise_history_page.dart';
import '../models/workout_model.dart';
import 'sets_table.dart';

class ExecutionExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  final bool isInitiallyExpanded;

  /// Called when any set is marked complete — use this to trigger a rest timer.
  final VoidCallback? onSetRestTimerRequested;

  const ExecutionExerciseCard({
    super.key,
    required this.exercise,
    this.isInitiallyExpanded = false,
    this.onSetRestTimerRequested,
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
                  exerciseId: widget.exercise.id,
                  sets: widget.exercise.workoutSets,
                  onSetCompleted: widget.onSetRestTimerRequested,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseHistoryPage(
                              exercise: widget.exercise,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('Histórico & Evolução'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
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
