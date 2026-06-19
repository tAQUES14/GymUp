import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gym_feedback.dart';
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

class _WorkoutStepPageState extends State<WorkoutStepPage> with WidgetsBindingObserver {
  // ── Workout data ──────────────────────────────────────────────────────────
  WorkoutModel? _workout;
  int _currentExerciseIndex = 0;
  int _currentSeriesIndex = 0;
  int _completedExercises = 0;
  int _completedSets = 0;      // series marcadas como feitas (só avança)
  int _maxProgressSent = 0;    // garante que progresso nunca regride

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
  List<FocusNode> _weightFocusNodes = [];
  double _lastKeyboardInset = 0;
  int _lastSyncedExerciseId = -1;
  final Map<int, int> _seriesIndexByExerciseId = {};
  final Map<int, Map<int, String>> _draftWeights = {};
  final Map<int, Map<int, String>> _draftReps = {};
  Timer? _setsSaveDebounce;

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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onCtrlUpdate);
    _ctrl.dispose();
    _elapsedTimer?.cancel();
    _timer?.cancel();
    _setsSaveDebounce?.cancel();
    _progressMsgTimer?.cancel();
    for (final c in _seriesCtrls) { c.dispose(); }
    for (final c in _repsCtrls) { c.dispose(); }
    for (final f in _weightFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentInset = MediaQuery.viewInsetsOf(context).bottom;
      final keyboardJustClosed = _lastKeyboardInset > 0 && currentInset == 0;
      _lastKeyboardInset = currentInset;
      if (keyboardJustClosed) {
        FocusScope.of(context).unfocus();
      }
    });
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
      await _restoreExecutionState(session);
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
    // Progress is based on sets checked by the user, never on navigation position.
    // It can only go forward — _maxProgressSent prevents any regression.
    final totalSets = _workout?.exercises.fold<int>(0, (s, e) => s + _seriesCount(e)) ?? 1;
    final rawProgress = totalSets > 0
        ? ((_completedSets / totalSets) * 100).round().clamp(0, 100)
        : 0;
    final progress = rawProgress > _maxProgressSent ? rawProgress : _maxProgressSent;
    _maxProgressSent = progress;
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
      if (e.toString().contains('404')) {
        await _clearExecutionState();
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esse treino ja foi encerrado. Atualizando sua tela...'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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

  String? get _executionStateKey {
    final sessionId = _session?.id;
    final workoutId = _workout?.id;
    if (sessionId == null || workoutId == null) return null;
    return 'workout_execution_state_${sessionId}_$workoutId';
  }

  void _rememberCurrentSeries() {
    if (_workout == null || _workout!.exercises.isEmpty) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    _seriesIndexByExerciseId[exercise.id] = _currentSeriesIndex;
  }

  int _clampIndex(int value, int min, int max) {
    if (max < min) return min;
    return value.clamp(min, max).toInt();
  }

  int _rememberedSeriesIndexFor(ExerciseModel exercise) {
    final maxIndex = _seriesCount(exercise) - 1;
    final remembered = _seriesIndexByExerciseId[exercise.id] ?? 0;
    return _clampIndex(remembered, 0, maxIndex);
  }

  double _parseWeight(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  void _captureControllerDrafts(ExerciseModel exercise) {
    final totalSeries = _seriesCount(exercise);
    for (int i = 0; i < totalSeries; i++) {
      final setNum = i + 1;
      final weight = _seriesCtrls.length > i ? _seriesCtrls[i].text.trim() : '';
      final reps = _repsCtrls.length > i ? _repsCtrls[i].text.trim() : '';
      if (weight.isNotEmpty) {
        _draftWeights.putIfAbsent(exercise.id, () => {})[setNum] = weight;
      }
      if (reps.isNotEmpty) {
        _draftReps.putIfAbsent(exercise.id, () => {})[setNum] = reps;
      }
    }
  }

  Future<void> _persistExecutionState() async {
    final key = _executionStateKey;
    if (key == null || _workout == null) return;
    _rememberCurrentSeries();
    _captureControllerDrafts(_workout!.exercises[_currentExerciseIndex]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode({
      'exercise_index': _currentExerciseIndex,
      'series_index': _currentSeriesIndex,
      'completed_exercises': _completedExercises,
      'completed_sets': _completedSets,
      'max_progress_sent': _maxProgressSent,
      'series_by_exercise': _seriesIndexByExerciseId.map((k, v) => MapEntry('$k', v)),
      'weights': _draftWeights.map(
        (exerciseId, sets) => MapEntry('$exerciseId', sets.map((k, v) => MapEntry('$k', v))),
      ),
      'reps': _draftReps.map(
        (exerciseId, sets) => MapEntry('$exerciseId', sets.map((k, v) => MapEntry('$k', v))),
      ),
    }));
  }

  Future<void> _clearExecutionState() async {
    final key = _executionStateKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> _restoreExecutionState(WorkoutSessionData session) async {
    if (_workout == null || _workout!.exercises.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'workout_execution_state_${session.id}_${_workout!.id}';
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      final fromProgress = ((session.progress / 100) * _workout!.exercises.length).floor();
      _currentExerciseIndex = _clampIndex(fromProgress, 0, _workout!.exercises.length - 1);
      _currentSeriesIndex = 0;
      _completedExercises = _currentExerciseIndex;
      _maxProgressSent = session.progress.clamp(0, 100);
      return;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final exerciseIndex = (data['exercise_index'] as num?)?.toInt() ?? 0;
      _currentExerciseIndex = _clampIndex(exerciseIndex, 0, _workout!.exercises.length - 1);
      _currentSeriesIndex = _clampIndex(
        (data['series_index'] as num?)?.toInt() ?? 0,
        0,
        _seriesCount(_workout!.exercises[_currentExerciseIndex]) - 1,
      );
      _completedExercises = _clampIndex(
        (data['completed_exercises'] as num?)?.toInt() ?? _currentExerciseIndex,
        0,
        _workout!.exercises.length,
      );
      final totalSets = _workout!.exercises.fold<int>(0, (s, e) => s + _seriesCount(e));
      _completedSets = ((data['completed_sets'] as num?)?.toInt() ?? 0).clamp(0, totalSets);
      _maxProgressSent = ((data['max_progress_sent'] as num?)?.toInt() ?? 0).clamp(0, 100);

      void readNestedStringMap(dynamic source, Map<int, Map<int, String>> target) {
        if (source is! Map) return;
        source.forEach((exerciseKey, setsValue) {
          final exerciseId = int.tryParse('$exerciseKey');
          if (exerciseId == null || setsValue is! Map) return;
          final sets = target.putIfAbsent(exerciseId, () => {});
          setsValue.forEach((setKey, value) {
            final setNum = int.tryParse('$setKey');
            if (setNum != null && '$value'.trim().isNotEmpty) {
              sets[setNum] = '$value';
            }
          });
        });
      }

      if (data['series_by_exercise'] is Map) {
        (data['series_by_exercise'] as Map).forEach((exerciseKey, value) {
          final exerciseId = int.tryParse('$exerciseKey');
          final idx = value is num ? value.toInt() : int.tryParse('$value');
          if (exerciseId != null && idx != null) _seriesIndexByExerciseId[exerciseId] = idx;
        });
      }

      readNestedStringMap(data['weights'], _draftWeights);
      readNestedStringMap(data['reps'], _draftReps);
    } catch (_) {}
  }

  void _syncWeightField() {
    if (_workout == null || !mounted) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    final totalSeries = _seriesCount(exercise);

    // Recreate controllers when exercise changes or set count changes
    if (_lastSyncedExerciseId != exercise.id ||
        _seriesCtrls.length != totalSeries) {
      for (final c in _seriesCtrls) { c.dispose(); }
      for (final c in _repsCtrls) { c.dispose(); }
      for (final f in _weightFocusNodes) { f.dispose(); }
      _seriesCtrls = List.generate(totalSeries, (_) => TextEditingController());
      _repsCtrls   = List.generate(totalSeries, (_) => TextEditingController());
      _weightFocusNodes = List.generate(totalSeries, (_) => FocusNode());
      _lastSyncedExerciseId = exercise.id;

      // Pre-fill reps from cache (if available)
      _applyLastSetsToControllers(exercise.id, exercise.reps, totalSeries);
    }

    // Sync weight from execution controller
    for (int i = 0; i < totalSeries; i++) {
      final setNum = i + 1;
      final draftWeight = _draftWeights[exercise.id]?[setNum];
      final draftReps = _draftReps[exercise.id]?[setNum];
      final w = _ctrl.getWeight(exercise.id, setNum);
      final text = draftWeight ??
          (w > 0
              ? (w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1))
              : '');
      if (_seriesCtrls[i].text != text) {
        _seriesCtrls[i].text = text;
        _seriesCtrls[i].selection = TextSelection.collapsed(offset: text.length);
      }
      if (draftReps != null && _repsCtrls[i].text != draftReps) {
        _repsCtrls[i].text = draftReps;
        _repsCtrls[i].selection = TextSelection.collapsed(offset: draftReps.length);
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

  Future<void> _flushExerciseSets(ExerciseModel exercise) async {
    final sessionId = _session?.id;
    if (sessionId == null) return;

    final totalSeries = _seriesCount(exercise);
    final sets = <Map<String, dynamic>>[];

    for (int i = 0; i < totalSeries; i++) {
      final weight = _parseWeight(_seriesCtrls.length > i ? _seriesCtrls[i].text : '');
      final reps = int.tryParse(
        _repsCtrls.length > i ? _repsCtrls[i].text : '',
      ) ?? exercise.reps;
      sets.add({'set_number': i + 1, 'weight': weight, 'reps': reps});
    }

    await _workoutService.saveWorkoutSets(
      sessionId:  sessionId,
      exerciseId: exercise.id,
      sets:       sets,
    );
  }

  /// Save current exercise sets to the backend (fire-and-forget).
  void _saveExerciseSets(ExerciseModel exercise) {
    _flushExerciseSets(exercise).catchError((_) {});
  }

  void _onSetFieldChanged(ExerciseModel exercise, int setNum) {
    final index = setNum - 1;
    if (index < 0) return;

    final weight = _seriesCtrls.length > index ? _seriesCtrls[index].text.trim() : '';
    final reps = _repsCtrls.length > index ? _repsCtrls[index].text.trim() : '';

    _draftWeights.putIfAbsent(exercise.id, () => {})[setNum] = weight;
    _draftReps.putIfAbsent(exercise.id, () => {})[setNum] = reps;
    _rememberCurrentSeries();

    final parsedWeight = _parseWeight(weight);
    if (parsedWeight > 0) {
      final parsedReps = int.tryParse(reps) ?? exercise.reps;
      _ctrl.setWeight(exercise.id, setNum, parsedWeight, reps: parsedReps);
    }

    _persistExecutionState();
    _setsSaveDebounce?.cancel();
    _setsSaveDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _saveExerciseSets(exercise);
    });
  }

  void _saveWeight([int? seriesNumber]) {
    if (_workout == null) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    if (exercise.id <= 0) return;

    final setNum = seriesNumber ?? _currentSeriesIndex + 1;
    final ctrlIndex = setNum - 1;

    double weight = 0;
    if (ctrlIndex >= 0 && ctrlIndex < _seriesCtrls.length) {
      weight = _parseWeight(_seriesCtrls[ctrlIndex].text);
    }
    if (weight <= 0) {
      weight = _ctrl.getWeight(exercise.id, setNum);
    }
    if (weight <= 0) return;

    final reps = ctrlIndex >= 0 && ctrlIndex < _repsCtrls.length
        ? int.tryParse(_repsCtrls[ctrlIndex].text) ?? exercise.reps
        : exercise.reps;

    _ctrl.setWeight(exercise.id, setNum, weight, reps: reps);
    _captureControllerDrafts(exercise);
    _saveExerciseSets(exercise);
    _persistExecutionState();
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

    // Conta esta série como concluída e sincroniza progresso imediatamente.
    // Progresso só avança — nunca regride (garantido por _maxProgressSent).
    _completedSets++;
    _sendProgress(_workout!.exercises.length);

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
        _rememberCurrentSeries();
        _currentSetReady = false;
      });
      _persistExecutionState();
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
        // Last set of last exercise: skip rest timer, go straight to completion
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
    final weight = _parseWeight(
      _seriesCtrls.length > completedIdx ? _seriesCtrls[completedIdx].text : '',
    );

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
      _rememberCurrentSeries();
      _currentExerciseIndex++;
      _currentSeriesIndex = _rememberedSeriesIndexFor(exercises[_currentExerciseIndex]);
    });
    _syncWeightField();
    _prefillFromLastSets(exercises[_currentExerciseIndex].id);
    _persistExecutionState();
    _sendProgress(exercises.length);
  }

  void _nextExercise() {
    final exercises = _workout!.exercises;
    if (_currentExerciseIndex < exercises.length - 1) {
      _saveExerciseSets(exercises[_currentExerciseIndex]);
      _rememberCurrentSeries();
      _cancelRest();
      setState(() {
        _currentExerciseIndex++;
        _currentSeriesIndex = _rememberedSeriesIndexFor(exercises[_currentExerciseIndex]);
        _currentSetReady = false;
      });
      _syncWeightField();
      _prefillFromLastSets(exercises[_currentExerciseIndex].id);
      _persistExecutionState();
      _sendProgress(exercises.length);
    }
  }

  void _prevExercise() {
    if (_currentExerciseIndex > 0) {
      _saveExerciseSets(_workout!.exercises[_currentExerciseIndex]);
      _rememberCurrentSeries();
      _cancelRest();
      setState(() {
        _currentExerciseIndex--;
        _currentSeriesIndex = _rememberedSeriesIndexFor(_workout!.exercises[_currentExerciseIndex]);
        _currentSetReady = false;
      });
      _syncWeightField();
      _persistExecutionState();
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
    final weight = _parseWeight(_seriesCtrls[idx].text);
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
    final currWeight = _parseWeight(
      _seriesCtrls.length > setIndex ? _seriesCtrls[setIndex].text : '',
    );
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
      _setsSaveDebounce?.cancel();
      await _flushExerciseSets(_workout!.exercises[_currentExerciseIndex]);
      await _persistExecutionState();
      final completedForProgress = _completedExercises.clamp(0, total);
      final syncProgress = ((completedForProgress / total) * 100).round().clamp(0, 100);
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

      final hasChallengeCelebration = finishResult.celebrations.any(
        (event) => (event['type'] as String? ?? '').startsWith('challenge_'),
      );

      for (final event in finishResult.celebrations) {
        if (!mounted) return;
        final type = event['type'] as String? ?? '';
        await _gymAchievementDialog(
          context,
          icon: type == 'achievement'
              ? Icons.workspace_premium_rounded
              : Icons.emoji_events_rounded,
          iconColor: type == 'achievement' ? _kDone : _kAmber,
          title: event['title'] as String? ?? 'Boa!',
          content: event['message'] as String? ?? 'Progresso salvo com sucesso.',
        );
      }
      if (!mounted) return;

      // Feedback de desafio ativo (aparece somente quando o treino conta pontos)
      final cp = finishResult.challengeProgress;
      if (cp != null && mounted && !hasChallengeCelebration) {
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

      await _clearExecutionState();
      if (!mounted) return;

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
            exerciseNames: widget.workout.exercises.map((e) => e.name).toList(),
            remainingWorkoutsThisWeek: finishResult.remainingWorkoutsThisWeek,
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
      if (e.toString().contains('404')) {
        await _clearExecutionState();
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esse treino ja foi encerrado. Atualizando sua tela...'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        return;
      }
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
    _persistExecutionState();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Computes meetsConditions locally in real-time, without depending on
  /// the cached backend response (_session.meetsConditions). This avoids a
  /// race condition where the user clicks exit before the async _sendProgress()
  /// response returns, causing a stale meetsConditions=false to be evaluated.
  bool get _localMeetsConditions {
    if (_session == null || _workout == null) return false;
    final totalSets = _workout!.exercises.fold<int>(0, (s, e) => s + _seriesCount(e));
    if (totalSets == 0) return false;
    // Usa o mesmo cálculo do _sendProgress (por série, só avança)
    final displayProgress = _maxProgressSent;
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildExecutionHeader(exercises.length),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Column(
                    children: [
                      _buildExecutionProgressCard(exercises.length),
                      const SizedBox(height: 18),
                      _buildExecutionExerciseView(
                        currentExercise,
                        totalSeries,
                        exercises.length,
                      ),
                    ],
                  ),
                ),
              ),
              _buildProgressBanner(),
              _buildExecutionDock(exercises, totalSeries),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutionHeader(int totalExercises) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handlePopAttempt,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0E1116),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TREINO EM ANDAMENTO',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF9AA3B0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    color: const Color(0xFF0E1116),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1116),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F84A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8F84A).withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _elapsedPillLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _elapsedPillLabel {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    if (_elapsed.inHours > 0) {
      return _elapsedFormatted;
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildExecutionProgressCard(int totalExercises) {
    final minSecs = (_session?.minMinutes ?? 1) * 60;
    final elapsedSecs = _elapsed.inSeconds;
    final minProgress = _session?.minProgress ?? 75;
    final localProgress =
        (((_completedExercises > _currentExerciseIndex
                        ? _completedExercises
                        : _currentExerciseIndex) /
                    totalExercises.clamp(1, 999)) *
                100)
            .round()
            .clamp(0, 100);
    final displayProgress = _session == null
        ? localProgress
        : (localProgress > _session!.progress
            ? localProgress
            : _session!.progress);
    final exerciseProgress = totalExercises == 0
        ? 0.0
        : ((_currentExerciseIndex + 1) / totalExercises).clamp(0.0, 1.0);

    String mmss(int seconds) {
      return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PROGRESSO DO TREINO',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF9AA3B0),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_currentExerciseIndex + 1}',
                      style: const TextStyle(
                        color: Color(0xFF2F6FED),
                        fontSize: 13,
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalExercises',
                      style: const TextStyle(
                        color: Color(0xFF9AA3B0),
                        fontSize: 13,
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'exerc.',
                style: TextStyle(
                  color: Color(0xFF5B6472),
                  fontSize: 10.5,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: exerciseProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFF2F6FED).withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F6FED),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildProgressMetric(
                icon: Icons.timer_outlined,
                value: mmss(elapsedSecs),
                goal: mmss(minSecs),
              ),
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF9AA3B0),
                  shape: BoxShape.circle,
                ),
              ),
              _buildProgressMetric(
                icon: Icons.fitness_center_rounded,
                value: '$displayProgress%',
                goal: '$minProgress%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required IconData icon,
    required String value,
    required String goal,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9AA3B0)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0E1116),
            fontSize: 11.5,
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        Text(
          ' / $goal',
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF9AA3B0),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionExerciseView(
    ExerciseModel exercise,
    int totalSeries,
    int totalExercises,
  ) {
    final repsLabel = exercise.reps.toString();
    return Column(
      children: [
        _buildExecutionGifCard(exercise, totalExercises),
        const SizedBox(height: 16),
        _buildExecutionExerciseSummary(exercise),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildExecutionStat('$totalSeries', 'SERIES')),
            const SizedBox(width: 10),
            Expanded(child: _buildExecutionStat(repsLabel, 'REPS')),
            const SizedBox(width: 10),
            Expanded(
              child: _buildExecutionStat('${exercise.rest}', 'DESCANSO', unit: 's'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildExecutionSeriesList(exercise, totalSeries),
      ],
    );
  }

  Widget _buildExecutionGifCard(ExerciseModel exercise, int totalExercises) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: exercise)),
      ),
      child: Container(
        height: 229,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.35, -0.22),
            end: Alignment(0.65, 1.22),
            colors: [Color(0xFFE7EEFE), Color(0xFFF0FFD9)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x0A0E1116)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExerciseGifPanel(exercise: exercise, height: 229, paused: true),
            ),
            Positioned(
              left: 13,
              top: 13,
              child: _buildDarkPill('${_currentExerciseIndex + 1} / $totalExercises'),
            ),
            Positioned(
              right: 13,
              top: 13,
              child: _buildDarkPill('GIF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xC60E1116),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildExecutionExerciseSummary(ExerciseModel exercise) {
    final muscle = exercise.muscleGroup.isEmpty ? 'EXERCICIO' : exercise.muscleGroup.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EEFE),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        muscle,
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF1F4FC4),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                        color: const Color(0xFF0E1116),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseProgressPage(exercise: exercise),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDFBD3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Color(0xFF5BA300),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: const Color(0x0F0E1116)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryAction(
                icon: Icons.play_circle_outline_rounded,
                label: 'Ver execucao',
                color: const Color(0xFF2F6FED),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailPage(exercise: exercise),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0x140E1116),
              ),
              _buildSummaryAction(
                icon: Icons.swap_horiz_rounded,
                label: 'Substituir',
                color: const Color(0xFF5B6472),
                onTap: _showSubstitutionSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionStat(String value, String label, {String? unit}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0E1116),
                  fontSize: 19,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFF9AA3B0),
                    fontSize: 10.5,
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: const Color(0xFF5B6472),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionSeriesList(ExerciseModel exercise, int totalSeries) {
    final completedCount = List.generate(totalSeries, (i) => i + 1)
        .where((setNum) =>
            _ctrl.isSetCompleted(exercise.id, setNum) ||
            setNum <= _currentSeriesIndex)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Series',
              style: AppTypography.bodyLarge.copyWith(
                color: const Color(0xFF0E1116),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Text(
              '$completedCount/$totalSeries',
              style: const TextStyle(
                color: Color(0xFF5B6472),
                fontSize: 11,
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(totalSeries, (index) {
          final setNum = index + 1;
          final isDone = _ctrl.isSetCompleted(exercise.id, setNum) ||
              index < _currentSeriesIndex ||
              (_isResting &&
                  index == _currentSeriesIndex &&
                  (_restType == RestType.betweenExercises || _isAllDone));
          final isCurrent = index == _currentSeriesIndex && !isDone;
          final repsCtrl = _repsCtrls.length > index ? _repsCtrls[index] : null;
          final reps = repsCtrl?.text.trim().isNotEmpty == true
              ? repsCtrl!.text.trim()
              : exercise.reps.toString();
          final weight = _displayWeight(exercise, setNum, index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildExecutionSetCard(
              exercise: exercise,
              setNum: setNum,
              reps: reps,
              weight: weight,
              isCurrent: isCurrent,
              isDone: isDone,
            ),
          );
        }),
      ],
    );
  }

  String _displayWeight(ExerciseModel exercise, int setNum, int index) {
    final text = _seriesCtrls.length > index ? _seriesCtrls[index].text : '';
    final parsed = _parseWeight(text);
    final value = parsed > 0 ? parsed : _ctrl.getWeight(exercise.id, setNum);
    if (value <= 0) return '0 kg';
    return value == value.roundToDouble()
        ? '${value.toInt()} kg'
        : '${value.toStringAsFixed(1)} kg';
  }

  Widget _buildExecutionSetCard({
    required ExerciseModel exercise,
    required int setNum,
    required String reps,
    required String weight,
    required bool isCurrent,
    required bool isDone,
  }) {
    final muted = !isCurrent && !isDone;
    final borderColor = isCurrent
        ? const Color(0xFF2F6FED)
        : isDone
            ? const Color(0x335BA300)
            : const Color(0x0F0E1116);
    final bgColor = isCurrent
        ? Colors.white
        : isDone
            ? const Color(0xFFF0FFD9)
            : const Color(0xFFF7F9FC);
    final accentColor = isCurrent
        ? const Color(0xFF2F6FED)
        : isDone
            ? const Color(0xFF5BA300)
            : const Color(0xFF9AA3B0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCurrent ? 12 : 13,
        vertical: isCurrent ? 13 : 12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF2F6FED).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: isCurrent
          ? Column(
              children: [
                _buildSetCardHeader(
                  setNum: setNum,
                  reps: reps,
                  weight: weight,
                  isCurrent: true,
                  isDone: isDone,
                  muted: muted,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactRepsStepper(
                        setNum: setNum,
                        reps: reps,
                        active: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactKgStepper(
                        exercise: exercise,
                        setNum: setNum,
                        weight: weight,
                        active: true,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                _buildSetCardHeader(
                  setNum: setNum,
                  reps: reps,
                  weight: weight,
                  isCurrent: false,
                  isDone: isDone,
                  muted: muted,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactRepsStepper(
                        setNum: setNum,
                        reps: reps,
                        active: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactKgStepper(
                        exercise: exercise,
                        setNum: setNum,
                        weight: weight,
                        active: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSetCardHeader({
    required int setNum,
    required String reps,
    required String weight,
    required bool isCurrent,
    required bool isDone,
    required bool muted,
    required Color accentColor,
  }) {
    return Row(
      children: [
        _setNumberBadge(
          setNum: setNum,
          isCurrent: isCurrent,
          isDone: isDone,
          muted: muted,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrent
                    ? 'SERIE $setNum - ATUAL'
                    : isDone
                        ? 'SERIE $setNum - FEITA'
                        : 'SERIE $setNum',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: accentColor,
                  fontSize: isCurrent ? 10 : 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$reps reps  -  $weight',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF0E1116),
                  fontSize: isCurrent ? 14.5 : 13.5,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _setNumberBadge({
    required int setNum,
    required bool isCurrent,
    required bool isDone,
    required bool muted,
  }) {
    return Container(
      width: isCurrent ? 36 : 40,
      height: isCurrent ? 36 : 40,
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF2F6FED)
            : isDone
                ? const Color(0xFF5BA300)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: muted ? Border.all(color: const Color(0x140E1116)) : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF2F6FED).withValues(alpha: 0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isDone && !isCurrent
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : Text(
                '$setNum',
                style: TextStyle(
                  color: isCurrent ? Colors.white : const Color(0xFF9AA3B0),
                  fontSize: isCurrent ? 15 : 14,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildCompactRepsStepper({
    required int setNum,
    required String reps,
    required bool active,
  }) {
    final color = active ? const Color(0xFF2F6FED) : const Color(0xFF5B6472);
    return _buildInlineStepper(
      active: active,
      color: color,
      minCenterWidth: active ? 54 : 42,
      onMinus: () => _adjustReps(setNum, -1),
      onPlus: () => _adjustReps(setNum, 1),
      child: Text(
        '$reps reps',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: active ? 12 : 11,
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildCompactKgStepper({
    required ExerciseModel exercise,
    required int setNum,
    required String weight,
    required bool active,
  }) {
    final color = active ? const Color(0xFF2F6FED) : const Color(0xFF5B6472);
    final ctrlIndex = setNum - 1;
    final controller = ctrlIndex >= 0 && ctrlIndex < _seriesCtrls.length
        ? _seriesCtrls[ctrlIndex]
        : null;
    final focusNode = ctrlIndex >= 0 && ctrlIndex < _weightFocusNodes.length
        ? _weightFocusNodes[ctrlIndex]
        : null;
    return _buildInlineStepper(
      active: active,
      color: color,
      minCenterWidth: active ? 62 : 56,
      onMinus: () => _adjustWeight(exercise, setNum, -5),
      onPlus: () => _adjustWeight(exercise, setNum, 5),
      child: controller == null
          ? Text(
              weight,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: active ? 46 : 42,
                  height: active ? 26 : 24,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_isFinishing,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    cursorHeight: 14,
                    cursorWidth: 1.5,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([,.]\d{0,1})?')),
                    ],
                    style: TextStyle(
                      color: color,
                      fontSize: active ? 12.5 : 12,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      height: 1,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: '0',
                      contentPadding: EdgeInsets.only(bottom: 1),
                    ),
                    onEditingComplete: () {
                      _saveWeight(setNum);
                      FocusScope.of(context).unfocus();
                    },
                    onTap: () {
                      final node = focusNode;
                      setState(() {
                        _currentSeriesIndex = ctrlIndex;
                        _rememberCurrentSeries();
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        node?.requestFocus();
                        controller.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: controller.text.length,
                        );
                      });
                    },
                    onChanged: (_) {
                      _onSetFieldChanged(exercise, setNum);
                      if (ctrlIndex == _currentSeriesIndex) {
                        _checkSetReadiness();
                      }
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      _saveWeight(setNum);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'kg',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.72),
                    fontSize: active ? 10 : 9,
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInlineStepper({
    required bool active,
    required Color color,
    required double minCenterWidth,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required Widget child,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      width: active ? double.infinity : null,
      padding: EdgeInsets.all(active ? 4 : 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7EEFE) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active ? const Color(0x3F2F6FED) : const Color(0x140E1116),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildStepperButton(
            icon: Icons.remove_rounded,
            active: active,
            onTap: onMinus,
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minCenterWidth),
              child: SizedBox(
                height: active ? 25 : 21,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
          _buildStepperButton(
            icon: Icons.add_rounded,
            active: active,
            filled: active,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }

  void _adjustReps(int setNum, int delta) {
    final ctrlIndex = setNum - 1;
    if (ctrlIndex < 0 || ctrlIndex >= _repsCtrls.length) return;
    if (_workout == null) return;
    final exercise = _workout!.exercises[_currentExerciseIndex];
    final current = int.tryParse(_repsCtrls[ctrlIndex].text) ?? 0;
    final next = (current + delta).clamp(0, 999).toInt();
    final text = next > 0 ? next.toString() : '';
    setState(() {
      _repsCtrls[ctrlIndex].text = text;
      _repsCtrls[ctrlIndex].selection =
          TextSelection.collapsed(offset: text.length);
    });
    if (ctrlIndex == _currentSeriesIndex) {
      _checkSetReadiness();
    }
    _onSetFieldChanged(exercise, setNum);
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: active ? 26 : 22,
        height: active ? 26 : 22,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF2F6FED) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: active ? 16 : 14,
          color: filled
              ? Colors.white
              : active
                  ? const Color(0xFF1F4FC4)
                  : const Color(0xFF9AA3B0),
        ),
      ),
    );
  }

  Widget _buildExecutionDock(List<ExerciseModel> exercises, int totalSeries) {
    if (_isResting) {
      return _buildExecutionRestDock();
    }

    final canGoPrev = _currentExerciseIndex > 0;
    final canGoNext = _currentExerciseIndex < exercises.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        7,
        14,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border.all(color: const Color(0x0F0E1116)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
            blurRadius: 34,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _markSeriesDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(0.21, -1.25),
                  end: Alignment(0.79, 2.25),
                  colors: [Color(0xFF1F4FC4), Color(0xFF2F6FED), Color(0xFF4A8CFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F6FED).withValues(alpha: 0.36),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isAllDone ? 'Finalizar treino' : 'Concluir serie',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDockIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: canGoPrev ? _prevExercise : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXERCICIO',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF9AA3B0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_currentExerciseIndex + 1}',
                            style: const TextStyle(
                              color: Color(0xFF2F6FED),
                              fontSize: 13,
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${exercises.length}',
                            style: const TextStyle(
                              color: Color(0xFF9AA3B0),
                              fontSize: 13,
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDockIconButton(
                icon: Icons.arrow_forward_rounded,
                onTap: canGoNext ? _nextExercise : null,
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0x140E1116),
              ),
              GestureDetector(
                onTap: _isFinishing ? null : _onFimPressed,
                child: Opacity(
                  opacity: _isFinishing ? 0.5 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFF5B6472),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Encerrar',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF5B6472),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
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
      ),
    );
  }

  Widget _buildExecutionRestDock() {
    final progress = _restTotal > 0
        ? (_restCountdown / _restTotal).clamp(0.0, 1.0)
        : 0.0;
    final minutes = _restCountdown ~/ 60;
    final seconds = _restCountdown % 60;
    final timeLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final subtitle = _restSubtitleLabel();
    const actionsWidth = 174.0;

    return Container(
      margin: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xF40E1116),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E1116).withValues(alpha: 0.32),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8F84A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC8F84A).withValues(alpha: 0.70),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'DESCANSO',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                timeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: actionsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _restCountdown = (_restCountdown + 15).clamp(0, 999);
                          _restTotal = (_restTotal + 15).clamp(1, 999);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '+15s',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _skipRest,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8F84A),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.skip_next_rounded,
                              color: Color(0xFF1F4FC4),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Pular',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF1F4FC4),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8F84A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _restSubtitleLabel() {
    if (_restType == RestType.betweenExercises) {
      final exercises = _workout?.exercises ?? const <ExerciseModel>[];
      final nextIndex = _currentExerciseIndex + 1;
      if (nextIndex < exercises.length) {
        return 'PROXIMO: ${exercises[nextIndex].name.toUpperCase()}';
      }
    }

    final label = (_restCompletedLabel ?? 'Serie concluida')
        .replaceAll('Ã—', 'x')
        .replaceAll('×', 'x')
        .toUpperCase();
    return 'ULTIMA SERIE: $label';
  }

  Widget _buildDockIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: const Color(0xFF5B6472), size: 17),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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
                        onChanged: (_) {
                          _onSetFieldChanged(exercise, setNum);
                          if (isCurrent) _checkSetReadiness();
                        },
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
                          _onSetFieldChanged(exercise, setNum);
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
    final parsedCurrent = _parseWeight(_seriesCtrls[ctrlIndex].text);
    final current = parsedCurrent > 0
        ? parsedCurrent
        : _ctrl.getWeight(exercise.id, setNum);
    final newWeight = (current + delta).clamp(0.0, 9999.0);
    final text = newWeight == newWeight.roundToDouble()
        ? newWeight.toInt().toString()
        : newWeight.toStringAsFixed(1);
    setState(() {
      _seriesCtrls[ctrlIndex].text = text;
      _seriesCtrls[ctrlIndex].selection =
          TextSelection.collapsed(offset: text.length);
    });
    _onSetFieldChanged(exercise, setNum);
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
    return showGymConfirmDialog(
      context,
      title: title,
      message: content,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      icon: icon,
      color: confirmColor ?? iconColor,
      destructive: confirmColor == AppColors.error || iconColor == AppColors.error,
    );
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
