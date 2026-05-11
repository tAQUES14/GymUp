import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'controllers/workout_execution_controller.dart';
import 'models/workout_model.dart';
import 'widgets/exercise_image_widget.dart';
import 'workout_api_service.dart';
import 'exercise_detail_page.dart';
import 'exercise_progress_page.dart';
import 'workout_complete_page.dart';

const _kBlue = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kDone = Color(0xFF10B981); // emerald — estado "concluído"
const _kAmber = Color(0xFFF59E0B);

enum RestType { none, betweenSets, betweenExercises }

class WorkoutStepPage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutStepPage({super.key, required this.workout});

  @override
  State<WorkoutStepPage> createState() => _WorkoutStepPageState();
}

class _WorkoutStepPageState extends State<WorkoutStepPage> {
  // ── Workout data ──────────────────────────────────────────────────────────
  WorkoutModel? _workout;
  int _currentExerciseIndex = 0;
  int _currentSeriesIndex = 0;
  int _completedExercises = 0;

  // ── Session ───────────────────────────────────────────────────────────────
  final WorkoutApiService _workoutService = WorkoutApiService();
  late final WorkoutExecutionController _ctrl;
  WorkoutSessionData? _session;
  DateTime? _sessionStart;
  bool _pointsGranted = false;
  bool _isFinishing = false;
  // Guard: prevents double-tap spam after the last set is marked done.
  bool _isAllDone = false;

  // ── Elapsed timer ─────────────────────────────────────────────────────────
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // ── Weight + Reps per series ──────────────────────────────────────────────
  List<TextEditingController> _seriesCtrls = [];
  List<TextEditingController> _repsCtrls   = [];
  int _lastSyncedExerciseId = -1;

  // ── Rest timer ────────────────────────────────────────────────────────────
  Timer? _timer;
  int _restSessionId = 0; // incrementado a cada _startRest/_skip/_cancel
  int _restCountdown = 0;
  int _restTotal = 0; // for progress arc

  // Tipo de descanso ativo; none = não está descansando.
  RestType _restType = RestType.none;
  bool get _isResting => _restType != RestType.none;

  // Rest-mode: label for the set just completed (e.g. "12 × 45 kg")
  String? _restCompletedLabel;

  // ── Set readiness & inline progress ───────────────────────────────────────
  bool _currentSetReady = false;
  String? _setProgressMsg;
  Timer? _progressMsgTimer;

  // ── Last-sets cache (pre-fill + last workout display) ─────────────────────
  /// Maps exercise_id → enriched last-sets snapshot from the previous session.
  final Map<int, ExerciseLastSets> _lastSetsCache = {};
  final Set<int> _prefillRequested = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _ctrl = WorkoutExecutionController(workout: widget.workout);
    _ctrl.addListener(_onCtrlUpdate);
    _ctrl.loadAllWeights().then((_) {
      if (mounted) _syncWeightField();
    });
    _loadSession();
    // Pre-fetch last sets for the first exercise
    if (_workout!.exercises.isNotEmpty) {
      _prefillFromLastSets(_workout!.exercises.first.id);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlUpdate);
    _ctrl.dispose();
    _elapsedTimer?.cancel();
    _timer?.cancel();
    _progressMsgTimer?.cancel();
    for (final c in _seriesCtrls) { c.dispose(); }
    for (final c in _repsCtrls) { c.dispose(); }
    super.dispose();
  }

  void _onCtrlUpdate() {
    if (mounted) _syncWeightField();
  }

  // ── Session loading ───────────────────────────────────────────────────────

  Future<void> _loadSession() async {
    try {
      final session = await _workoutService.getStatus();
      if (!mounted || session == null) return;
      // Use the backend-validated elapsed_seconds (already capped at 6h) to seed
      // the local timer. A synthetic _sessionStart is derived so the timer's
      // DateTime.now().difference(_sessionStart!) computation stays accurate
      // as the session continues ticking.
      final syncedElapsed = Duration(seconds: session.elapsedSeconds);
      final syntheticStart = DateTime.now().subtract(syncedElapsed);
      setState(() {
        _session = session;
        _sessionStart = syntheticStart;
        _pointsGranted = session.pointsGranted;
        _elapsed = syncedElapsed;
      });
      _startElapsedTimer();
      _syncWeightField();
    } catch (_) {}
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStart != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_sessionStart!));
      }
    });
  }

  // ── Progress reporting ────────────────────────────────────────────────────

  Future<void> _sendProgress(int totalExercises) async {
    // Use the furthest point reached: either exercises explicitly marked done
    // or the current index (when user skipped forward via the arrow).
    final best = _completedExercises > _currentExerciseIndex
        ? _completedExercises
        : _currentExerciseIndex;
    final progress = ((best / totalExercises) * 100).round().clamp(0, 100);
    try {
      final session = await _workoutService.updateProgress(progress);
      if (!mounted) return;
      // Always sync session so meetsConditions / progress stay current.
      setState(() {
        _session = session;
        if (session.pointsGranted) _pointsGranted = true;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      // Surface the error — silently swallowing it leaves the user without points.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (_session?.dailyPointsAlreadyGranted ?? false)
                ? 'Erro ao atualizar progresso.'
                : 'Erro ao atualizar progresso. Sem isso você não ganha pontos.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Weight ────────────────────────────────────────────────────────────────

  void _syncWeightField() {
    if (_workout == null || !mounted) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    final totalSeries = _seriesCount(exercise);

    // Recreate controllers when exercise changes or set count changes
    if (_lastSyncedExerciseId != exercise.id ||
        _seriesCtrls.length != totalSeries) {
      for (final c in _seriesCtrls) { c.dispose(); }
      for (final c in _repsCtrls) { c.dispose(); }
      _seriesCtrls = List.generate(totalSeries, (_) => TextEditingController());
      _repsCtrls   = List.generate(totalSeries, (_) => TextEditingController());
      _lastSyncedExerciseId = exercise.id;

      // Pre-fill reps from cache (if available)
      _applyLastSetsToControllers(exercise.id, exercise.reps, totalSeries);
    }

    // Sync weight from execution controller
    for (int i = 0; i < totalSeries; i++) {
      final w = _ctrl.getWeight(exercise.id, i + 1);
      final text = w > 0
          ? (w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1))
          : '';
      if (_seriesCtrls[i].text != text) {
        _seriesCtrls[i].text = text;
        _seriesCtrls[i].selection = TextSelection.collapsed(offset: text.length);
      }
    }
  }

  /// Apply cached last-sets data to weight and reps controllers.
  /// Only fills fields that the user hasn't already touched (empty fields).
  void _applyLastSetsToControllers(int exerciseId, int defaultReps, int totalSeries) {
    final cached = _lastSetsCache[exerciseId];

    for (int i = 0; i < totalSeries; i++) {
      final setNumber = i + 1;

      // Reps: fill from cache or fall back to plan default
      if (_repsCtrls[i].text.isEmpty) {
        final cachedSet = cached?.sets.firstWhere(
          (s) => (s['set'] as num?)?.toInt() == setNumber ||
                 (s['set_number'] as num?)?.toInt() == setNumber,
          orElse: () => <String, dynamic>{},
        );
        final reps = (cachedSet?['reps'] as num?)?.toInt() ?? defaultReps;
        final repsText = reps > 0 ? reps.toString() : '';
        _repsCtrls[i].text = repsText;
        _repsCtrls[i].selection = TextSelection.collapsed(offset: repsText.length);
      }

      // Weight: fill from cache only if execution controller has no weight yet
      if (cached != null && _seriesCtrls[i].text.isEmpty) {
        final cachedSet = cached.sets.firstWhere(
          (s) => (s['set'] as num?)?.toInt() == setNumber ||
                 (s['set_number'] as num?)?.toInt() == setNumber,
          orElse: () => <String, dynamic>{},
        );
        final weight = (cachedSet['weight'] as num?)?.toDouble() ?? 0.0;
        if (weight > 0 && _ctrl.getWeight(exerciseId, setNumber) <= 0) {
          _ctrl.setWeight(exerciseId, setNumber, weight);
          final weightText = weight == weight.roundToDouble()
              ? weight.toInt().toString()
              : weight.toStringAsFixed(1);
          _seriesCtrls[i].text = weightText;
          _seriesCtrls[i].selection = TextSelection.collapsed(offset: weightText.length);
        }
      }
    }
  }

  /// Fetch last-sets for an exercise and populate the cache.
  /// Triggers a re-sync of controllers if we're still on that exercise.
  void _prefillFromLastSets(int exerciseId) {
    if (_prefillRequested.contains(exerciseId)) return;
    _prefillRequested.add(exerciseId);

    _workoutService.getLastSets(exerciseId).then((lastSets) {
      if (!mounted || lastSets == null) return;
      setState(() => _lastSetsCache[exerciseId] = lastSets);
      // Re-sync only if we're still showing this exercise
      if (_workout != null &&
          _workout!.exercises[_currentExerciseIndex].id == exerciseId) {
        _syncWeightField();
      }
    }).catchError((_) {});
  }

  /// Save current exercise sets to the backend (fire-and-forget).
  void _saveExerciseSets(ExerciseModel exercise) {
    final sessionId = _session?.id;
    if (sessionId == null) return;

    final totalSeries = _seriesCount(exercise);
    final sets = <Map<String, dynamic>>[];

    for (int i = 0; i < totalSeries; i++) {
      final weight = double.tryParse(
        _seriesCtrls.length > i ? _seriesCtrls[i].text : '',
      ) ?? 0.0;
      final reps = int.tryParse(
        _repsCtrls.length > i ? _repsCtrls[i].text : '',
      ) ?? exercise.reps;
      sets.add({'set_number': i + 1, 'weight': weight, 'reps': reps});
    }

    _workoutService.saveWorkoutSets(
      sessionId:  sessionId,
      exerciseId: exercise.id,
      sets:       sets,
    ).catchError((_) {});
  }

  void _saveWeight([int? seriesNumber]) {
    if (_workout == null) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    if (exercise.id <= 0) return;

    final setNum = seriesNumber ?? _currentSeriesIndex + 1;
    final ctrlIndex = setNum - 1;

    double weight = 0;
    if (ctrlIndex >= 0 && ctrlIndex < _seriesCtrls.length) {
      weight = double.tryParse(_seriesCtrls[ctrlIndex].text) ?? 0;
    }
    if (weight <= 0) {
      weight = _ctrl.getWeight(exercise.id, setNum);
    }
    if (weight <= 0) return;

    _ctrl.setWeight(exercise.id, setNum, weight);
  }

  // ── Series / Exercise navigation ──────────────────────────────────────────

  int _seriesCount(ExerciseModel exercise) => exercise.sets;

  void _markSeriesDone() {
    // Guard: all exercises done — just re-open the finish dialog (no extra saves).
    if (_isAllDone) {
      _onFimPressed();
      return;
    }

    HapticFeedback.lightImpact();

    final exercise = _workout!.exercises[_currentExerciseIndex];
    final totalSeries = _seriesCount(exercise);
    final completedIdx = _currentSeriesIndex;
    _saveWeight(completedIdx + 1);

    // Capture completed-set data for rest-mode display
    _captureRestComparisonData(exercise, completedIdx);

    // Compute inline progress vs last workout for this set
    _computeSetProgress(exercise, completedIdx);

    if (completedIdx < totalSeries - 1) {
      // Not the last set: advance to next set + between-set rest
      setState(() {
        _currentSeriesIndex++;
        _currentSetReady = false;
      });
      _syncWeightField();
      _startRest(RestType.betweenSets, exercise.rest);
    } else {
      // Last set of this exercise
      final exercises = _workout!.exercises;
      final hasNextExercise = _currentExerciseIndex < exercises.length - 1;

      if (hasNextExercise) {
        // Between-exercise rest — _onRestFinished will call _goToNextExercise
        _startRest(RestType.betweenExercises, widget.workout.betweenExerciseRestSeconds);
      } else {
        // Last exercise: keep existing behavior
        _startRest(RestType.betweenSets, exercise.rest);
        _completeExercise();
      }
    }
  }

  String _fmtKg(double v) =>
      v == v.roundToDouble() ? '${v.toInt()} kg' : '${v.toStringAsFixed(1)} kg';

  void _captureRestComparisonData(ExerciseModel exercise, int completedIdx) {
    final reps = int.tryParse(
          _repsCtrls.length > completedIdx ? _repsCtrls[completedIdx].text : '') ??
        0;
    final weight = double.tryParse(
          _seriesCtrls.length > completedIdx ? _seriesCtrls[completedIdx].text : '') ??
        0.0;

    final completedLabel = reps > 0 || weight > 0
        ? '$reps × ${_fmtKg(weight)}'
        : null;

    setState(() {
      _restCompletedLabel = completedLabel;
    });
  }

  // Chamado somente quando o último exercício é concluído.
  Future<void> _completeExercise() async {
    final exercises = _workout!.exercises;
    _completedExercises++;
    _saveExerciseSets(exercises[_currentExerciseIndex]);
    _isAllDone = true;
    await _sendProgress(exercises.length);
    if (!mounted) return;
    setState(() {});
    _onFimPressed();
  }

  // Chamado por _onRestFinished quando o descanso entre exercícios termina.
  void _goToNextExercise() {
    final exercises = _workout!.exercises;
    final completedExercise = exercises[_currentExerciseIndex];
    _completedExercises++;
    _saveExerciseSets(completedExercise);
    setState(() {
      _currentExerciseIndex++;
      _currentSeriesIndex = 0;
    });
    _syncWeightField();
    _prefillFromLastSets(exercises[_currentExerciseIndex].id);
    _sendProgress(exercises.length);
  }

  void _nextExercise() {
    final exercises = _workout!.exercises;
    if (_currentExerciseIndex < exercises.length - 1) {
      _saveExerciseSets(exercises[_currentExerciseIndex]);
      _cancelRest();
      setState(() {
        _currentExerciseIndex++;
        _currentSeriesIndex = 0;
        _currentSetReady = false;
      });
      _syncWeightField();
      _prefillFromLastSets(exercises[_currentExerciseIndex].id);
      _sendProgress(exercises.length);
    }
  }

  void _prevExercise() {
    if (_currentExerciseIndex > 0) {
      _saveExerciseSets(_workout!.exercises[_currentExerciseIndex]);
      _cancelRest();
      setState(() {
        _currentExerciseIndex--;
        _currentSeriesIndex = 0;
        _currentSetReady = false;
      });
      _syncWeightField();
    }
  }

  // ── Rest timer ────────────────────────────────────────────────────────────

  void _startRest(RestType type, int seconds) {
    // Incrementa o session ID — qualquer timer da sessão anterior ignorará seu callback.
    _restSessionId++;
    final session = _restSessionId;

    _timer?.cancel();

    if (seconds <= 0) {
      _restType = type;
      _onRestFinished();
      return;
    }

    setState(() {
      _restType = type;
      _restCountdown = seconds;
      _restTotal = seconds;
      if (type == RestType.betweenExercises) _restCompletedLabel = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Descarta ticks de sessões antigas ou quando a página foi destruída.
      if (!mounted || session != _restSessionId) { timer.cancel(); return; }
      if (_restCountdown > 1) {
        setState(() => _restCountdown--);
      } else {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _onRestFinished();
      }
    });
  }

  // Ponto único de encerramento do descanso — captura o tipo antes de resetar.
  void _onRestFinished() {
    final finishedType = _restType;
    setState(() {
      _restType = RestType.none;
      _restCountdown = 0;
    });
    if (finishedType == RestType.betweenExercises) {
      _goToNextExercise();
    }
  }

  void _cancelRest() {
    _timer?.cancel();
    _restSessionId++; // invalida qualquer tick pendente
    if (_restType != RestType.none) {
      setState(() {
        _restType = RestType.none;
        _restCountdown = 0;
      });
    }
  }

  void _skipRest() {
    _timer?.cancel();
    _restSessionId++; // invalida qualquer tick pendente antes de chamar _onRestFinished
    HapticFeedback.lightImpact();
    _onRestFinished();
  }

  // ── Set readiness ─────────────────────────────────────────────────────────

  void _checkSetReadiness() {
    if (_workout == null || !mounted) return;
    final idx = _currentSeriesIndex;
    if (idx >= _seriesCtrls.length || idx >= _repsCtrls.length) return;
    final weight = double.tryParse(_seriesCtrls[idx].text) ?? 0;
    final reps   = int.tryParse(_repsCtrls[idx].text) ?? 0;
    final ready  = weight > 0 && reps > 0;
    if (ready != _currentSetReady) {
      setState(() => _currentSetReady = ready);
    }
  }

  // ── Inline progress after a set ───────────────────────────────────────────

  void _computeSetProgress(ExerciseModel exercise, int setIndex) {
    final cached = _lastSetsCache[exercise.id];
    if (cached == null || !cached.hasData) return;

    final setNum = setIndex + 1;
    final currWeight = double.tryParse(
          _seriesCtrls.length > setIndex ? _seriesCtrls[setIndex].text : '') ??
        0;
    final currReps = int.tryParse(
          _repsCtrls.length > setIndex ? _repsCtrls[setIndex].text : '') ??
        0;

    final lastSet = cached.sets.firstWhere(
      (s) =>
          (s['set'] as num?)?.toInt() == setNum ||
          (s['set_number'] as num?)?.toInt() == setNum,
      orElse: () => <String, dynamic>{},
    );
    final lastWeight = (lastSet['weight'] as num?)?.toDouble() ?? 0;
    final lastReps   = (lastSet['reps'] as num?)?.toInt() ?? 0;

    String? msg;
    if (currWeight > lastWeight && lastWeight > 0) {
      final diff = currWeight - lastWeight;
      final kg = diff == diff.roundToDouble()
          ? diff.toInt().toString()
          : diff.toStringAsFixed(1);
      msg = '+${kg}kg nesta série 🔥';
    } else if (currReps > lastReps && lastReps > 0 && currWeight >= lastWeight) {
      msg = '+${currReps - lastReps} rep nesta série 💪';
    }

    if (msg == null) return;

    _progressMsgTimer?.cancel();
    setState(() => _setProgressMsg = msg);
    _progressMsgTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _setProgressMsg = null);
    });
  }

  // ── Finish workout ────────────────────────────────────────────────────────

  Future<void> _onFimPressed() async {
    final bool isBonusSession = _session?.dailyPointsAlreadyGranted ?? false;

    // Bonus session: no points at stake — always a simple confirmation.
    if (isBonusSession) {
      final confirm = await _gymConfirmDialog(
        context,
        icon: Icons.check_circle_outline_rounded,
        iconColor: _kBlue,
        title: 'Finalizar treino?',
        content: 'Deseja encerrar o treino agora?',
        cancelLabel: 'Continuar treino',
        confirmLabel: 'Finalizar',
      );
      if (!confirm || !mounted) return;
      _finishWorkout();
      return;
    }

    // Conditions are met if the backend confirmed it (meetsConditions) OR
    // computed locally in real-time (guards against stale async responses) OR
    // points were already granted in a previous progress sync.
    final bool conditionsMet =
        _pointsGranted || (_session?.meetsConditions ?? false) || _localMeetsConditions;

    if (!conditionsMet) {
      final shouldLeave = await _gymConfirmDialog(
        context,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.error,
        title: 'Sair do treino?',
        content: 'Se você sair agora, não receberá pontos.',
        cancelLabel: 'Continuar',
        confirmLabel: 'Sair mesmo assim',
        confirmColor: AppColors.error,
      );
      if (!shouldLeave || !mounted) return;
    } else {
      final confirm = await _gymConfirmDialog(
        context,
        icon: Icons.check_circle_outline_rounded,
        iconColor: _kBlue,
        title: 'Finalizar treino?',
        content: 'Deseja encerrar o treino agora?',
        cancelLabel: 'Continuar treino',
        confirmLabel: 'Finalizar',
      );
      if (!confirm || !mounted) return;
    }
    _finishWorkout();
  }

  // BUG 1 fix: parâmetro confirmPartial para tratar o ciclo PARTIAL_CONFIRM.
  // BUG 2 fix: usa WorkoutFinishResult como fonte de verdade — sem hardcode.
  Future<void> _finishWorkout({bool confirmPartial = false}) async {
    if (!mounted) return;
    setState(() => _isFinishing = true);
    _elapsedTimer?.cancel();
    try {
      // 1. Sincroniza progresso com o backend antes da avaliação de pontos.
      final total = _workout!.exercises.length;
      final best = _completedExercises > _currentExerciseIndex
          ? _completedExercises
          : _currentExerciseIndex;
      final syncProgress = ((best / total) * 100).round().clamp(0, 100);
      await _workoutService.updateProgress(syncProgress);

      // 2. Finaliza a sessão — backend é a fonte de verdade.
      // Usa _sessionStart (vindo do backend) para calcular duração exata no
      // momento do finish, evitando divergência com o _elapsed cacheado.
      final durationSeconds = _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).inSeconds
          : _elapsed.inSeconds;
      final finishResult = await _workoutService.finishWorkout(
        completionPercent: syncProgress,
        durationSeconds: durationSeconds,
        confirmPartial: confirmPartial,
      );

      if (!mounted) return;

      // Treino parcial (70–74%): sessão ainda aberta, aguarda confirmação.
      if (finishResult.isPartialConfirm) {
        setState(() => _isFinishing = false);
        _startElapsedTimer();
        final confirmed = await _gymConfirmDialog(
          context,
          icon: Icons.info_outline_rounded,
          iconColor: _kAmber,
          title: 'Treino incompleto',
          content: finishResult.message,
          cancelLabel: 'Cancelar',
          confirmLabel: 'Confirmar',
          confirmColor: _kAmber,
          barrierDismissible: false,
        );
        if (confirmed == true && mounted) {
          await _finishWorkout(confirmPartial: true);
        }
        return;
      }

      // VALID ou INVALID — a sessão já está fechada no backend em ambos os casos.
      // Para INVALID: treino contado, porém sem pontos (motivo exibido na tela de conclusão).

      // Modal de meta semanal — aparece naturalmente só uma vez/semana,
      // pois weekly_goal_just_completed só é true quando o count cruza exatamente
      // a meta pela primeira vez.
      if (finishResult.weeklyGoalJustCompleted && mounted) {
        await _gymAchievementDialog(
          context,
          icon: Icons.local_fire_department_rounded,
          iconColor: _kDone,
          title: 'Meta semanal concluída!',
          content:
              'Você manteve seu streak.\nContinue treinando para aumentar ainda mais.',
        );
        if (!mounted) return;
      }

      // Feedback de desafio ativo (aparece somente quando o treino conta pontos)
      final cp = finishResult.challengeProgress;
      if (cp != null && mounted) {
        final String challengeMsg = _buildChallengeMessage(cp);
        await _gymAchievementDialog(
          context,
          icon: Icons.emoji_events_rounded,
          iconColor: _kAmber,
          title: 'Desafio',
          content: challengeMsg,
        );
        if (!mounted) return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutCompletePage(
            workoutNome: widget.workout.name,
            duracaoMinutos: _elapsed.inMinutes,
            setsConcluidos: _completedExercises,
            setsTotais: total,
            streak: finishResult.streakCurrent,
            pontosGerados: finishResult.pointsGenerated,
            totalPontos: finishResult.totalPoints,
            noPointsReason: finishResult.isInvalid
                ? finishResult.message
                : null,
            progressMessage: finishResult.progressMessage,
            prMessages: finishResult.prMessages,
            workoutVolume: finishResult.workoutVolume,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      // Erro de rede — restaura estado para o usuário poder tentar novamente.
      setState(() => _isFinishing = false);
      _startElapsedTimer();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sem conexão. Não foi possível finalizar o treino. Tente novamente.',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Tentar novamente',
            // Preserva o contexto de confirmPartial caso o erro tenha ocorrido
            // durante a segunda chamada (após o usuário confirmar parcial).
            onPressed: () => _finishWorkout(confirmPartial: confirmPartial),
          ),
        ),
      );
    }
  }

  // ── Challenge progress message ────────────────────────────────────────────

  String _buildChallengeMessage(Map<String, dynamic> cp) {
    final type = cp['type'] as String?;
    if (type == 'simple') {
      final current = (cp['my_workouts'] as num?)?.toInt() ?? 0;
      final goal = (cp['goal_workouts'] as num?)?.toInt() ?? 0;
      final justDone = cp['simple_goal_just_completed'] == true;
      if (justDone) return 'Desafio concluido! $current / $goal treinos';
      return '+1 treino no desafio\n$current / $goal treinos';
    }
    final position = (cp['my_position'] as num?)?.toInt();
    if (position != null) return 'Voce esta em ${position}o lugar no desafio';
    return 'Progresso registrado no desafio!';
  }

  // ── Back button / pop handling ────────────────────────────────────────────

  void _handlePopAttempt() {
    if (_isFinishing || _session == null) {
      Navigator.of(context).pop();
      return;
    }
    _showExitModal().then((shouldPop) {
      if (shouldPop && mounted) Navigator.of(context).pop();
    });
  }

  Future<bool> _showExitModal() async {
    if (_pointsGranted) {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Pontos garantidos!', style: AppTypography.h3),
              content: Text(
                'Seus pontos já estão garantidos, mas o treino não foi finalizado. Deseja sair mesmo assim?',
                style: AppTypography.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Continuar treino',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sair mesmo assim'),
                ),
              ],
            ),
          ) ??
          false;
    } else if (_session?.dailyPointsAlreadyGranted ?? false) {
      // Bonus session: no points at stake, simple exit.
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Sair do treino?', style: AppTypography.h3),
              content: Text(
                'Deseja sair do treino?',
                style: AppTypography.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Continuar treino',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sair'),
                ),
              ],
            ),
          ) ??
          false;
    } else if ((_session?.meetsConditions ?? false) || _localMeetsConditions) {
      // Critérios atingidos mas treino ainda não finalizado.
      // Oferece finalizar (garantindo pontos) ou sair sem finalizar.
      final result =
          await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Treino já validado!', style: AppTypography.h3),
              content: Text(
                'Seu treino já atingiu os critérios mínimos. Finalize para garantir seus pontos ou saia sem finalizar.',
                style: AppTypography.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'exit'),
                  child: Text(
                    'Sair sem finalizar',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, 'finish'),
                  child: const Text('Finalizar treino'),
                ),
              ],
            ),
          ) ??
          'cancel';

      if (result == 'finish' && mounted) {
        _finishWorkout();
        return false; // _finishWorkout navega para WorkoutCompletePage
      }
      return result == 'exit';
    } else {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Sair do treino?', style: AppTypography.h3),
              content: Text(
                'Se você sair agora, não receberá pontos.',
                style: AppTypography.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Continuar treino',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sair sem pontos'),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  // ── Exercise substitution ─────────────────────────────────────────────────

  Future<void> _showSubstitutionSheet() async {
    if (_workout == null) return;
    final original = _workout!.exercises[_currentExerciseIndex];

    List<Map<String, dynamic>>? subs;
    bool loading = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (loading && subs == null) {
              _workoutService.getSubstitutions(original.id).then((result) {
                if (ctx.mounted) setSheetState(() { subs = result; loading = false; });
              }).catchError((_) {
                if (ctx.mounted) setSheetState(() { subs = []; loading = false; });
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (_, scrollCtrl) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Substituir exercício', style: AppTypography.h3),
                          const SizedBox(height: 2),
                          Text(
                            'Alternativas para ${original.name}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : subs!.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma substituição cadastrada.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: subs!.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final sub = subs![index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      sub['name'] as String? ?? '',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      sub['muscle_group'] as String? ?? '',
                                      style: AppTypography.caption,
                                    ),
                                    trailing: TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _swapExercise(sub, original);
                                      },
                                      child: const Text('Usar'),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _swapExercise(Map<String, dynamic> sub, ExerciseModel original) {
    final replacement = ExerciseModel(
      id:          (sub['id'] as num).toInt(),
      name:        sub['name'] as String? ?? '',
      muscleGroup: sub['muscle_group'] as String? ?? '',
      defaultRest: original.defaultRest,
      sets:        original.sets,
      reps:        original.reps,
      rest:        original.rest,
      carga:       original.carga,
    );

    setState(() {
      _workout!.exercises[_currentExerciseIndex] = replacement;
      _currentSeriesIndex = 0;
    });
    _syncWeightField();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Computes meetsConditions locally in real-time, without depending on
  /// the cached backend response (_session.meetsConditions). This avoids a
  /// race condition where the user clicks exit before the async _sendProgress()
  /// response returns, causing a stale meetsConditions=false to be evaluated.
  bool get _localMeetsConditions {
    if (_session == null || _workout == null) return false;
    final total = _workout!.exercises.length;
    if (total == 0) return false;
    final best = _completedExercises > _currentExerciseIndex
        ? _completedExercises
        : _currentExerciseIndex;
    final localProgress = ((best / total) * 100).round().clamp(0, 100);
    final displayProgress =
        localProgress > _session!.progress ? localProgress : _session!.progress;
    final minSecs = _session!.minMinutes * 60;
    return _elapsed.inSeconds >= minSecs && displayProgress >= _session!.minProgress;
  }

  String get _elapsedFormatted {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_workout == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final exercises = _workout!.exercises;
    final currentExercise = exercises[_currentExerciseIndex];
    final totalSeries = _seriesCount(currentExercise);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handlePopAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildTopBar(),
            _buildRequirementsBlock(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildExerciseCard(
                  currentExercise,
                  totalSeries,
                  exercises.length,
                ),
              ),
            ),
            _buildProgressBanner(),
            _buildBottomDock(exercises, totalSeries),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final exercises = _workout!.exercises;
    final progress = exercises.isNotEmpty
        ? (_currentExerciseIndex / exercises.length).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlueDark],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 4,
        right: 16,
        bottom: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Linha principal ──────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _handlePopAttempt,
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: Text(
                  widget.workout.name,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _elapsedFormatted,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── Barra de progresso de exercícios ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Text(
                  '${_currentExerciseIndex + 1} / ${exercises.length}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Points banner ─────────────────────────────────────────────────────────

  Widget _buildPointsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            'Seus pontos já estão garantidos.',
            style: AppTypography.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status strip (compact) ────────────────────────────────────────────────

  Widget _buildRequirementsBlock() {
    if (_session == null) return const SizedBox.shrink();
    if (_pointsGranted) return _buildPointsBanner();

    // Bonus session: another session already granted points today.
    if (_session!.dailyPointsAlreadyGranted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        color: const Color(0xFFF8FAFC),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Treino extra (sem pontuação)',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Normal session: compact dual progress bars.
    final int minSecs = _session!.minMinutes * 60;
    final int elapsedSecs = _elapsed.inSeconds;
    final int total = _workout?.exercises.length ?? 1;
    final int localProgress =
        (((_completedExercises > _currentExerciseIndex
                        ? _completedExercises
                        : _currentExerciseIndex) /
                    total) *
                100)
            .round()
            .clamp(0, 100);
    final int displayProgress = localProgress > _session!.progress
        ? localProgress
        : _session!.progress;
    final int minProgress = _session!.minProgress;
    final bool timeOk = elapsedSecs >= minSecs;
    final bool progressOk = displayProgress >= minProgress;
    final Color timeColor = timeOk ? AppColors.accent : AppColors.textSecondary;
    final Color progColor = progressOk
        ? AppColors.accent
        : AppColors.textSecondary;

    String fmt(int s) =>
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                timeOk ? Icons.check_circle_rounded : Icons.timer_outlined,
                size: 13,
                color: timeColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${fmt(elapsedSecs)}/${fmt(minSecs)}',
                style: AppTypography.caption.copyWith(
                  color: timeColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: (elapsedSecs / minSecs).clamp(0.0, 1.0),
                  backgroundColor: timeColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(timeColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                progressOk
                    ? Icons.check_circle_rounded
                    : Icons.fitness_center_rounded,
                size: 13,
                color: progColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$displayProgress%/$minProgress%',
                style: AppTypography.caption.copyWith(
                  color: progColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: (displayProgress / minProgress).clamp(0.0, 1.0),
                  backgroundColor: progColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Muscle label (compact "Costas • Bíceps") ─────────────────────────────

  List<Widget> _buildMuscleLabel(ExerciseModel exercise) {
    final parts = <String>[];
    if (exercise.muscleGroup.isNotEmpty) parts.add(exercise.muscleGroup);
    if (exercise.primaryMuscle != null &&
        exercise.primaryMuscle!.toLowerCase() !=
            exercise.muscleGroup.toLowerCase()) {
      parts.add(exercise.primaryMuscle!);
    }
    parts.addAll(exercise.secondaryMuscles.take(2));
    final label = parts.join(' • ');
    if (label.isEmpty) return const [];
    return [
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTypography.caption.copyWith(
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  // ── Exercise card ─────────────────────────────────────────────────────────

  Widget _buildExerciseCard(
    ExerciseModel exercise,
    int totalSeries,
    int totalExercises,
  ) {
    final restTime = exercise.rest;
    final repsLabel = exercise.reps.toString();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── GIF full-width + número badge ────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseDetailPage(exercise: exercise),
              ),
            ),
            child: Stack(
              children: [
                ExerciseGifPanel(exercise: exercise, height: 200, paused: true),
                // Número do exercício
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${_currentExerciseIndex + 1} / $totalExercises',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                // Badge "toque para detalhes"
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Detalhes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nome + músculo + ícone de progresso ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.2,
                        ),
                      ),
                      ..._buildMuscleLabel(exercise),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseProgressPage(exercise: exercise),
                    ),
                  ),
                  child: Tooltip(
                    message: 'Ver progressão',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Ver execução | Substituir ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailPage(exercise: exercise),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                  label: const Text('Ver execução'),
                  style: TextButton.styleFrom(
                    foregroundColor: _kBlue,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showSubstitutionSheet,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Substituir'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // ── Stats: Séries | Reps | Descanso ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _StatBox(value: '$totalSeries', label: 'Séries'),
                    Container(width: 1, color: const Color(0xFFE2E8F0)),
                    _StatBox(value: repsLabel, label: 'Reps'),
                    Container(width: 1, color: const Color(0xFFE2E8F0)),
                    _StatBox(value: '${restTime}s', label: 'Descanso'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Lista de séries com campo de peso inline ─────────────────────
          _buildSeriesList(exercise, totalSeries),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Progress banner ───────────────────────────────────────────────────────

  Widget _buildProgressBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _setProgressMsg != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              color: _kDone.withValues(alpha: 0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: _kDone, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _setProgressMsg!,
                    style: const TextStyle(
                      color: _kDone,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Bottom dock ───────────────────────────────────────────────────────────

  Widget _buildBottomDock(List<ExerciseModel> exercises, int totalSeries) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: switch (_restType) {
            RestType.betweenExercises => const [Color(0xFFD97706), Color(0xFFB45309)],
            RestType.betweenSets      => const [Color(0xFF059669), Color(0xFF047857)],
            RestType.none             => const [_kBlue, _kBlueDark],
          },
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: _isResting
          ? _buildRestMode()
          : _buildActiveMode(exercises, totalSeries),
    );
  }

  // ── Rest mode ────────────────────────────────────────────────────────────

  Widget _buildRestMode() {
    final progress = _restTotal > 0 ? _restCountdown / _restTotal : 0.0;
    final minutes = _restCountdown ~/ 60;
    final secs = _restCountdown % 60;
    final label = minutes > 0
        ? '$minutes:${secs.toString().padLeft(2, '0')}'
        : '$secs s';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Last completed set summary ────────────────────────────────────
        if (_restCompletedLabel != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última série',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _restCompletedLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Next exercise info (between-exercise rest only) ───────────────
        if (_restType == RestType.betweenExercises) ...[
          _buildNextExerciseInfo(),
          const SizedBox(height: 10),
        ],

        // ── Countdown ────────────────────────────────────────────────────
        Text(
          _restType == RestType.betweenExercises ? 'Descanso entre exercícios' : 'Descansando',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 14),

        // ── Actions ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _restCountdown = (_restCountdown + 15).clamp(0, 999);
                  _restTotal = (_restTotal + 15).clamp(1, 999);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '+15s',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _skipRest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Pular',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Next exercise info card (shown in between-exercise rest) ─────────────

  Widget _buildNextExerciseInfo() {
    final exercises = _workout!.exercises;
    final nextIndex = _currentExerciseIndex + 1;
    if (nextIndex >= exercises.length) return const SizedBox.shrink();
    final next = exercises[nextIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          ExerciseImageWidget(exercise: next, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximo exercício',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (next.muscleGroup.isNotEmpty)
                  Text(
                    next.muscleGroup,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${next.sets} × ${next.reps}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active mode ──────────────────────────────────────────────────────────

  Widget _buildActiveMode(List<ExerciseModel> exercises, int totalSeries) {
    final canGoPrev = _currentExerciseIndex > 0;
    final canGoNext = _currentExerciseIndex < exercises.length - 1;
    final btnColor = _currentSetReady ? _kDone : AppColors.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Set dots indicator ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSeries, (i) {
            final exercise = exercises[_currentExerciseIndex];
            final setNum = i + 1;
            final done = _ctrl.isSetCompleted(exercise.id, setNum);
            final isCurrent = i == _currentSeriesIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: done
                    ? Colors.white
                    : isCurrent
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // ── Prev / Realizado / Next ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavButton(
              icon: Icons.arrow_back_ios_rounded,
              onPressed: canGoPrev ? _prevExercise : null,
            ),
            GestureDetector(
              onTap: _markSeriesDone,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: btnColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: btnColor.withValues(alpha: 0.45),
                      blurRadius: _currentSetReady ? 22 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Realizado',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              onPressed: canGoNext ? _nextExercise : null,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── List / counter / FIM ─────────────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => _showExerciseListSheet(exercises),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.list_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${_currentExerciseIndex + 1} / ${exercises.length}',
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isFinishing ? null : _onFimPressed,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isFinishing ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: _isFinishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'FIM',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onPressed != null
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.white30,
          size: 20,
        ),
      ),
    );
  }

  // ── Series list with inline weight fields ────────────────────────────────

  Widget _buildSeriesList(ExerciseModel exercise, int totalSeries) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text(
                  'Séries',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 62,
                  child: Text(
                    'Reps',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                const SizedBox(
                  width: 84,
                  child: Text(
                    'Peso',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(totalSeries, (index) {
            final setNum = index + 1;
            final isCurrent = index == _currentSeriesIndex;
            final isDone = index < _currentSeriesIndex;
            final weightCtrl = _seriesCtrls.length > index ? _seriesCtrls[index] : null;
            final repsCtrl   = _repsCtrls.length > index ? _repsCtrls[index] : null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.fromLTRB(14, 10, 14, isCurrent ? 8 : 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? _kBlue.withValues(alpha: 0.06)
                    : isDone
                    ? const Color(0xFFF0FDF4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? _kBlue
                      : isDone
                      ? _kDone
                      : const Color(0xFFE2E8F0),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Row(
                children: [
                  // Número da série
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _kBlue
                          : isDone
                          ? _kDone
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '$setNum',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1.0,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Série $setNum',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isCurrent ? _kBlue : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  // ── Reps field ───────────────────────────────────────────
                  if (repsCtrl != null)
                    SizedBox(
                      width: 62,
                      height: 38,
                      child: _buildSetTextField(
                        controller: repsCtrl,
                        isCurrent: isCurrent,
                        hint: '--',
                        suffix: 'x',
                        isDecimal: false,
                        onChanged: (_) { if (isCurrent) _checkSetReadiness(); },
                      ),
                    ),
                  const SizedBox(width: 6),
                  // ── Weight field ─────────────────────────────────────────
                  if (weightCtrl != null)
                    SizedBox(
                      width: 84,
                      height: 38,
                      child: _buildSetTextField(
                        controller: weightCtrl,
                        isCurrent: isCurrent,
                        hint: '–',
                        suffix: 'kg',
                        isDecimal: true,
                        onChanged: (value) {
                          final w = double.tryParse(value) ?? 0;
                          if (w > 0) _ctrl.setWeight(exercise.id, setNum, w);
                          if (isCurrent) _checkSetReadiness();
                        },
                      ),
                    ),
                ],
                ), // end Row
                if (isCurrent) ...[
                  const SizedBox(height: 8),
                  _buildQuickAdjustRow(exercise, setNum),
                ],
                ], // end Column children
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Quick weight adjustment ───────────────────────────────────────────────

  void _adjustWeight(ExerciseModel exercise, int setNum, double delta) {
    final ctrlIndex = setNum - 1;
    if (ctrlIndex >= _seriesCtrls.length) return;
    final current = double.tryParse(_seriesCtrls[ctrlIndex].text) ??
        _ctrl.getWeight(exercise.id, setNum);
    final newWeight = (current + delta).clamp(0.0, 9999.0);
    final text = newWeight == newWeight.roundToDouble()
        ? newWeight.toInt().toString()
        : newWeight.toStringAsFixed(1);
    setState(() {
      _seriesCtrls[ctrlIndex].text = text;
      _seriesCtrls[ctrlIndex].selection =
          TextSelection.collapsed(offset: text.length);
    });
    _ctrl.setWeight(exercise.id, setNum, newWeight);
  }

  Widget _buildQuickAdjustRow(ExerciseModel exercise, int setNum) {
    Widget stepBtn(String label, double delta, {bool isLeft = false}) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          _adjustWeight(exercise, setNum, delta);
        },
        child: Container(
          width: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: isLeft
                ? const BorderRadius.horizontal(left: Radius.circular(10))
                : const BorderRadius.horizontal(right: Radius.circular(10)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
      );
    }

    // Align the stepper to the right, exactly over the weight column
    return Row(
      children: [
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              stepBtn('−5', -5, isLeft: true),
              Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'kg',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
              stepBtn('+5', 5),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool> _gymConfirmDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required String cancelLabel,
    required String confirmLabel,
    Color? confirmColor,
    bool barrierDismissible = true,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: AppTypography.h3)),
              ],
            ),
            content: Text(content, style: AppTypography.bodyLarge),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  cancelLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor ?? _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _gymAchievementDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              content,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Incrível!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Exercise list sheet ───────────────────────────────────────────────────

  void _showExerciseListSheet(List<ExerciseModel> exercises) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Exercícios do treino', style: AppTypography.h3),
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: exercises.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final ex = exercises[index];
              final isDone = index < _currentExerciseIndex;
              final isCurrent = index == _currentExerciseIndex;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? _kDone.withValues(alpha: 0.10)
                        : isCurrent
                        ? _kBlue.withValues(alpha: 0.10)
                        : AppColors.background,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            color: _kDone,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTypography.caption.copyWith(
                              color: isCurrent
                                  ? _kBlue
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  ex.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isCurrent ? _kBlue : AppColors.textPrimary,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${_seriesCount(ex)} séries',
                  style: AppTypography.caption,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Compact text field for set weight / reps ────────────────────────────────

Widget _buildSetTextField({
  required TextEditingController controller,
  required bool isCurrent,
  required String hint,
  required String suffix,
  required bool isDecimal,
  required ValueChanged<String> onChanged,
}) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isCurrent ? _kBlue : const Color(0xFF1E293B),
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        fontSize: 10,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isCurrent ? _kBlue.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isCurrent ? _kBlue.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onChanged: onChanged,
  );
}

// ─── Caixa de stat (Séries / Reps / Descanso / Carga) ───────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
