import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'controllers/workout_execution_controller.dart';
import 'models/workout_model.dart';
import 'workout_complete_page.dart';


class WorkoutExecutionExercisePage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutExecutionExercisePage({super.key, required this.workout});

  @override
  State<WorkoutExecutionExercisePage> createState() =>
      _WorkoutExecutionExercisePageState();
}

class _WorkoutExecutionExercisePageState
    extends State<WorkoutExecutionExercisePage> {

  late final WorkoutExecutionController _ctrl;

  // ─── Navegação de exercício / série 
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;

  // ─── Timer ───────────────────────────────────────────────────────────────
  Timer? _workoutTimer;
  final ValueNotifier<Duration> _elapsedTime = ValueNotifier(Duration.zero);

  // ─── Campo de peso ───────────────────────────────────────────────────────
  // Um único campo que mostra o peso da série atual.
  late final TextEditingController _weightController;
  late final FocusNode _weightFocusNode;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // BUG CORRIGIDO: controller criado UMA VEZ aqui e nunca recriado.
    // Antes estava apenas como `_ctrl = WorkoutExecutionController(...)` sem
    // Provider, então cada navegação de volta para esta tela criava um novo
    // controller com _weights = {}.
    _ctrl = WorkoutExecutionController(workout: widget.workout);

    debugPrint(
      '[ExercisePage] initState — controller CRIADO '
      '(hashCode=${_ctrl.hashCode}) workout=${widget.workout.id}',
    );

    _weightController = TextEditingController();
    _weightFocusNode = FocusNode();
    _startWorkoutTimer();

    // Exibe SnackBar vermelho sempre que um save de carga falhar no backend.
    _ctrl.addListener(_onControllerSaveError);

    // Carrega pesos históricos do backend. Quando concluir, preenche o campo
    // da primeira série. A lógica de merge no controller garante que valores
    // já digitados pelo usuário NÃO sejam sobrescritos.
    _ctrl.loadAllWeights().then((_) {
      if (mounted) {
        _fillWeightFieldForCurrentSet();
      }
    });
  }

  void _onControllerSaveError() {
    if (!mounted) return;
    final err = _ctrl.saveError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
      _ctrl.clearSaveError();
    }
  }

  @override
  void dispose() {
    debugPrint(
      '[ExercisePage] dispose — controller DESTRUÍDO '
      '(hashCode=${_ctrl.hashCode})',
    );
    _ctrl.removeListener(_onControllerSaveError);
    _workoutTimer?.cancel();
    _elapsedTime.dispose();
    _ctrl.dispose();
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Timer
  // ─────────────────────────────────────────────────────────────────────────

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedTime.value = _elapsedTime.value + const Duration(seconds: 1);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Getters de conveniência
  // ─────────────────────────────────────────────────────────────────────────

  ExerciseModel get _currentExercise =>
      widget.workout.exercises[_currentExerciseIndex];

  WorkoutSet get _currentSet =>
      _currentExercise.workoutSets[_currentSetIndex];

  int get _totalExercises => widget.workout.exercises.length;

  // ─────────────────────────────────────────────────────────────────────────
  // Campo de peso
  // ─────────────────────────────────────────────────────────────────────────

  /// Preenche o campo de peso com o valor armazenado no controller para a
  /// série/exercício atual. Não modifica se o usuário estiver digitando.
  void _fillWeightFieldForCurrentSet() {
    if (!mounted) return;
    if (_weightFocusNode.hasFocus) return; // usuário digitando — não sobrescrever

    final w = _ctrl.getWeight(_currentExercise.id, _currentSet.number);
    final text = w > 0 ? w.toStringAsFixed(1) : '';

    debugPrint(
      '[ExercisePage] _fillWeightFieldForCurrentSet '
      'exercício=${_currentExercise.id} série=${_currentSet.number} '
      'peso=$w → campo="$text"',
    );

    _weightController.text = text;
    _weightController.selection = TextSelection.collapsed(
      offset: _weightController.text.length,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Troca de série
  // ─────────────────────────────────────────────────────────────────────────

  /// Avança para a próxima série do exercício atual.
  void _advanceToNextSet() {
    debugPrint(
      '[ExercisePage] TROCA DE SÉRIE: '
      '${_currentSetIndex + 1} → ${_currentSetIndex + 2} '
      '(exercício=${_currentExercise.id})',
    );
    setState(() => _currentSetIndex++);
    _fillWeightFieldForCurrentSet();
  }

  /// Retorna para a série anterior do exercício atual.
  void _goToPreviousSet() {
    if (_currentSetIndex == 0) return;
    debugPrint(
      '[ExercisePage] VOLTA DE SÉRIE: '
      '${_currentSetIndex + 1} → $_currentSetIndex '
      '(exercício=${_currentExercise.id})',
    );
    setState(() => _currentSetIndex--);
    _fillWeightFieldForCurrentSet();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Troca de exercício
  // ─────────────────────────────────────────────────────────────────────────

  void _advanceToNextExercise() {
    debugPrint(
      '[ExercisePage] TROCA DE EXERCÍCIO: '
      '${_currentExerciseIndex + 1} → ${_currentExerciseIndex + 2}',
    );
    setState(() {
      _currentExerciseIndex++;
      _currentSetIndex = 0;
    });
    _fillWeightFieldForCurrentSet();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Marcar concluído e avançar
  // ─────────────────────────────────────────────────────────────────────────

  void _onMarkDonePressed() {
    HapticFeedback.lightImpact();

    // Garante que o peso digitado seja salvo antes de avançar.
    final enteredWeight = double.tryParse(_weightController.text) ??
        _ctrl.getWeight(_currentExercise.id, _currentSet.number);

    debugPrint(
      '[ExercisePage] REALIZADO — exercício=${_currentExercise.id} '
      'série=${_currentSet.number} peso=$enteredWeight',
    );

    if (enteredWeight > 0) {
      _ctrl.setWeight(_currentExercise.id, _currentSet.number, enteredWeight);
    }
    _ctrl.markSetCompleted(_currentExercise.id, _currentSet.number, true);

    // Avança: próxima série → próximo exercício → finaliza
    if (_currentSetIndex < _currentExercise.sets - 1) {
      _advanceToNextSet();
    } else if (_currentExerciseIndex < _totalExercises - 1) {
      _advanceToNextExercise();
    } else {
      _finishWorkout();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Finalizar treino
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _finishWorkout() async {
    final durationMinutes = _elapsedTime.value.inMinutes;
    final completedExercises = _ctrl.completedExercisesCount;
    final totalExercises = _totalExercises;

    try {
      final result = await _ctrl.finishWorkout(
        durationMinutes: durationMinutes,
        exercisesCompleted: completedExercises,
        exercisesTotal: totalExercises,
      );

      final streak = result['streak'] ?? 1;
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutCompletePage(
            workoutNome: widget.workout.name,
            duracaoMinutos: durationMinutes,
            setsConcluidos: completedExercises,
            setsTotais: totalExercises,
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

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[ExercisePage] build — exercício=$_currentExerciseIndex '
      'série=$_currentSetIndex  '
      '_ctrl.hashCode=${_ctrl.hashCode}',
    );

    // Expõe o controller via Provider para que qualquer widget filho possa
    // acessá-lo com context.read/watch sem precisar de passagem manual.
    return ChangeNotifierProvider<WorkoutExecutionController>.value(
      value: _ctrl,
      child: _WorkoutExecutionExerciseBody(
        workout: widget.workout,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: _currentSetIndex,
        elapsedTime: _elapsedTime,
        weightController: _weightController,
        weightFocusNode: _weightFocusNode,
        onMarkDone: _onMarkDonePressed,
        onPreviousSet: _currentSetIndex > 0 ? _goToPreviousSet : null,
        ctrl: _ctrl,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WorkoutExecutionExerciseBody
//
// Widget puramente de UI extraído para evitar que o Provider.value acima
// recrie o controller a cada rebuild. O State pai (_WorkoutExecutionExercisePageState)
// é o dono único do controller.
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutExecutionExerciseBody extends StatelessWidget {
  final WorkoutModel workout;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final ValueNotifier<Duration> elapsedTime;
  final TextEditingController weightController;
  final FocusNode weightFocusNode;
  final VoidCallback onMarkDone;
  final VoidCallback? onPreviousSet;
  final WorkoutExecutionController ctrl;

  const _WorkoutExecutionExerciseBody({
    required this.workout,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.elapsedTime,
    required this.weightController,
    required this.weightFocusNode,
    required this.onMarkDone,
    required this.onPreviousSet,
    required this.ctrl,
  });

  ExerciseModel get _currentExercise => workout.exercises[currentExerciseIndex];
  WorkoutSet get _currentSet => _currentExercise.workoutSets[currentSetIndex];
  int get _totalExercises => workout.exercises.length;

  @override
  Widget build(BuildContext context) {
    final progress = ctrl.completedExercisesCount / _totalExercises;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Execução',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Barra de progresso
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surface,
            color: AppColors.primary,
            minHeight: 6,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Cronômetro
                ValueListenableBuilder<Duration>(
                  valueListenable: elapsedTime,
                  builder: (_, d, _) {
                    return Text(
                      '${d.inMinutes.toString().padLeft(2, '0')}:'
                      '${(d.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Contador exercício / série
                Text(
                  'Exercício ${currentExerciseIndex + 1} de $_totalExercises'
                  ' • Série ${currentSetIndex + 1} de ${_currentExercise.sets}',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 20),

                // Nome do exercício
                Text(
                  _currentExercise.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentSet.reps} repetições',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // Campo de peso
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Carga (kg): ', style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: weightController,
                        focusNode: weightFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            debugPrint(
                              '[ExercisePage] onChanged peso=$parsed '
                              'exercício=${_currentExercise.id} '
                              'série=${_currentSet.number}',
                            );
                            ctrl.setWeight(
                              _currentExercise.id,
                              _currentSet.number,
                              parsed,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Botão "voltar série" (visível apenas se não for a primeira série)
          if (onPreviousSet != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton.icon(
                onPressed: onPreviousSet,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Série anterior'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onMarkDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'REALIZADO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
