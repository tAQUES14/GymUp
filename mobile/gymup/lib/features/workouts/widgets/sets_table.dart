import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/workout_model.dart';

class SetsTable extends StatefulWidget {
  final List<WorkoutSet> sets;
  final Function(int setIndex, bool isCompleted) onSetCompleted;

  const SetsTable({
    super.key,
    required this.sets,
    required this.onSetCompleted,
  });

  @override
  State<SetsTable> createState() => _SetsTableState();
}

class _SetsTableState extends State<SetsTable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('SÉRIE', style: AppTypography.caption),
              ),
              Expanded(
                child: Text(
                  'CARGA (KG)',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'REPS',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // Checkbox space
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        // Rows
        ...widget.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          return _buildSetRow(index, set);
        }),
      ],
    );
  }

  Widget _buildSetRow(int index, WorkoutSet set) {
    final isDone = set.isCompleted;

    return Container(
      color: isDone
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent, // Green tint if done
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Set Number
          SizedBox(
            width: 40,
            child: Text(
              set.number.toString(),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDone ? AppColors.primary : Colors.white,
              ),
            ),
          ),
          // Weight Input
          Expanded(
            child: Center(
              child: _EditableField(
                initialValue: set.weight.toString(),
                onChanged: (val) {
                  setState(() {
                    set.weight = double.tryParse(val) ?? set.weight;
                  });
                },
                isDone: isDone,
              ),
            ),
          ),
          // Reps Input
          Expanded(
            child: Center(
              child: _EditableField(
                initialValue: set.reps.toString(),
                onChanged: (val) {
                  setState(() {
                    set.reps = int.tryParse(val) ?? set.reps;
                  });
                },
                isDone: isDone,
              ),
            ),
          ),
          // Checkbox
          SizedBox(
            width: 40,
            child: Center(
              child: Checkbox(
                value: isDone,
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                shape: const CircleBorder(),
                onChanged: (bool? value) {
                  if (value == true) {
                    widget.onSetCompleted(index, true);
                  } else {
                    widget.onSetCompleted(index, false);
                  }
                  setState(() {
                    // Parent will handle state update, but local setState triggers rebuild for green tint immediatly if we were managing state here.
                    // Since `set` is a reference, modifying it directly updates the model, but we should rely on callback for logic.
                    // However, for immediate UI feedback in this prototype, we can let the parent update.
                    // We will trust the parent callback to update the model.
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final bool isDone;

  const _EditableField({
    required this.initialValue,
    required this.onChanged,
    required this.isDone,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: widget.isDone
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: widget.isDone ? AppColors.primary : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12), // Adjust alignment
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
