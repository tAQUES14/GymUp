import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/workout_execution_controller.dart';
import '../models/workout_model.dart';

class SetsTable extends StatefulWidget {
  final int exerciseId;
  final List<WorkoutSet> sets;

  /// Optional: called when a set is marked complete (e.g., to show rest timer).
  final VoidCallback? onSetCompleted;

  const SetsTable({
    super.key,
    required this.exerciseId,
    required this.sets,
    this.onSetCompleted,
  });

  @override
  State<SetsTable> createState() => _SetsTableState();
}

class _SetsTableState extends State<SetsTable> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<FocusNode> _weightFocusNodes;

  WorkoutExecutionController? _ctrl;

  @override
  void initState() {
    super.initState();
    _weightControllers = List.generate(
      widget.sets.length,
      (_) => TextEditingController(),
    );
    _repsControllers = List.generate(
      widget.sets.length,
      (i) => TextEditingController(text: widget.sets[i].reps.toString()),
    );
    _weightFocusNodes = List.generate(
      widget.sets.length,
      (_) => FocusNode(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newCtrl = context.read<WorkoutExecutionController>();
    if (newCtrl != _ctrl) {
      _ctrl?.removeListener(_onControllerUpdate);
      _ctrl = newCtrl;
      _ctrl!.addListener(_onControllerUpdate);
      // Sync on first attachment (weights may already be loaded)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) _syncWeights();
        },
      );
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onControllerUpdate);
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    for (final f in _weightFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Sync: atualiza os text controllers a partir do model.
  // Campos com foco (usuário digitando) são sempre ignorados.
  // ──────────────────────────────────────────────

  void _syncWeights() {
    if (_ctrl == null || !mounted) return;
    for (int i = 0; i < widget.sets.length; i++) {
      if (_weightFocusNodes[i].hasFocus) continue; // usuário digitando — deixa

      final w = _ctrl!.getWeight(widget.exerciseId, widget.sets[i].number);
      final text = w > 0 ? w.toStringAsFixed(1) : '';

      if (_weightControllers[i].text != text) {

        _weightControllers[i].text = text;
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    _syncWeights();
    setState(() {}); // redesenha estado de conclusão / cores
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // BUG CORRIGIDO: antes usava context.read<>() em build(), que é um
    // antipadrão — o ctrl capturado nos callbacks poderia ficar stale.
    // Agora usa _ctrl (do state, sempre atual) para todas as operações.
    final ctrl = _ctrl;
    if (ctrl == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Cabeçalho
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
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),

        // Linhas de série
        ...widget.sets.asMap().entries.map((entry) {
          final i = entry.key;
          final set = entry.value;
          final isDone = ctrl.isSetCompleted(widget.exerciseId, set.number);
          return _SetRow(
            set: set,
            isDone: isDone,
            weightController: _weightControllers[i],
            repsController: _repsControllers[i],
            weightFocusNode: _weightFocusNodes[i],
            onWeightChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {

                // Usa _ctrl (state) em vez de ctrl capturado do build
                _ctrl?.setWeight(widget.exerciseId, set.number, parsed);
              }
            },
            onRepsChanged: (val) {
              set.reps = int.tryParse(val) ?? set.reps;
            },
            onToggleDone: (value) {
              final isCompleted = value == true;
              if (isCompleted) {
                final typed =
                    double.tryParse(_weightControllers[i].text) ?? 0;
                if (typed > 0) {

                  _ctrl?.setWeight(widget.exerciseId, set.number, typed);
                }
              }
              _ctrl?.markSetCompleted(
                widget.exerciseId,
                set.number,
                isCompleted,
              );
              if (isCompleted) widget.onSetCompleted?.call();
            },
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SetRow — recebe controllers já construídos; o estado sobrevive a rebuilds
// de SetsTable sem recriação.
// ─────────────────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final WorkoutSet set;
  final bool isDone;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final FocusNode weightFocusNode;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<bool?> onToggleDone;

  const _SetRow({
    required this.set,
    required this.isDone,
    required this.weightController,
    required this.repsController,
    required this.weightFocusNode,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDone
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Número da série
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

          // Campo de peso
          Expanded(
            child: Center(
              child: _InputBox(
                controller: weightController,
                focusNode: weightFocusNode,
                isDone: isDone,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: onWeightChanged,
              ),
            ),
          ),

          // Campo de reps
          Expanded(
            child: Center(
              child: _InputBox(
                controller: repsController,
                isDone: isDone,
                keyboardType: TextInputType.number,
                onChanged: onRepsChanged,
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
                onChanged: onToggleDone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InputBox — campo stateless; o controller é do _SetsTableState,
// por isso sobrevive a rebuilds.
// ─────────────────────────────────────────────────────────────────────────────

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDone;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _InputBox({
    required this.controller,
    this.focusNode,
    required this.isDone,
    required this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: isDone
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: isDone ? AppColors.primary : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
