import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'controllers/workout_execution_controller.dart';
import 'models/workout_model.dart';
import 'workout_api_service.dart';

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

  // ── Elapsed timer ─────────────────────────────────────────────────────────
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // ── Weight ────────────────────────────────────────────────────────────────
  final TextEditingController _weightController = TextEditingController();

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
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlUpdate);
    _ctrl.dispose();
    _elapsedTimer?.cancel();
    _weightController.dispose();
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
      final start = DateTime.parse(session.startedAt).toLocal();
      setState(() {
        _session = session;
        _sessionStart = start;
        _pointsGranted = session.pointsGranted;
        _elapsed = DateTime.now().difference(start);
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
            (_session?.isBonusSession ?? false)
                ? 'Erro ao atualizar progresso.'
                : 'Erro ao atualizar progresso. Sem isso você não ganha pontos.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Weight ────────────────────────────────────────────────────────────────

  /// Sincroniza o campo de texto com o valor armazenado no controller
  /// para o exercício/série atuais. Não sobrescreve se o usuário está digitando.
  void _syncWeightField() {
    if (_workout == null || !mounted) return;

    final exercise = _workout!.exercises[_currentExerciseIndex];
    final setNum = _currentSeriesIndex + 1;
    final w = _ctrl.getWeight(exercise.id, setNum);
    final text = w > 0 ? w.toStringAsFixed(1) : '';

    if (_weightController.text != text) {
      _weightController.text = text;
      _weightController.selection = TextSelection.collapsed(
        offset: _weightController.text.length,
      );
    }
  }

  /// Salva o peso para a série indicada.
  ///
  /// Primeiro tenta o valor digitado no campo de texto; se estiver vazio,
  /// usa o valor já armazenado no controller (fonte autoritativa).
  /// Isso evita que um _syncWeightField() assíncrono limpe o campo e
  /// faça o save ser silenciosamente descartado.
  void _saveWeight([int? seriesNumber]) {
    if (_workout == null) return;

    final exercise = _workout!.exercises[_currentExerciseIndex];
    if (exercise.id <= 0) return;

    final setNum = seriesNumber ?? _currentSeriesIndex + 1;

    // Tenta o campo de texto primeiro (pode ter sido editado pelo usuário).
    double weight = double.tryParse(_weightController.text) ?? 0;

    // Fallback: usa o valor já salvo no controller (ex: carregado do backend).
    if (weight <= 0) {
      weight = _ctrl.getWeight(exercise.id, setNum);
    }

    if (weight <= 0) {
      debugPrint(
        '[StepPage] _saveWeight SKIP: exerciseId=${exercise.id} '
        'setNum=$setNum weight=$weight (campo vazio e sem valor no controller)',
      );
      return;
    }

    debugPrint(
      '[StepPage] _saveWeight: exerciseId=${exercise.id} '
      'setNum=$setNum weight=$weight',
    );
    _ctrl.setWeight(exercise.id, setNum, weight);
  }

  // ── Series / Exercise navigation ──────────────────────────────────────────

  int _seriesCount(ExerciseModel exercise) => exercise.sets;

  void _markSeriesDone() {
    final exercise = _workout!.exercises[_currentExerciseIndex];
    final totalSeries = _seriesCount(exercise);
    // Salva o peso da série atual antes de avançar (fire-and-forget)
    _saveWeight(_currentSeriesIndex + 1);
    if (_currentSeriesIndex < totalSeries - 1) {
      setState(() => _currentSeriesIndex++);
      _syncWeightField();
    } else {
      _completeExercise();
    }
  }

  Future<void> _completeExercise() async {
    final exercises = _workout!.exercises;
    _completedExercises++;
    // peso já salvo por série em _markSeriesDone
    if (_currentExerciseIndex < exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSeriesIndex = 0;
      });
      _syncWeightField();
      _sendProgress(exercises.length); // fire-and-forget
    } else {
      // All exercises done — send final progress but do NOT navigate
      await _sendProgress(exercises.length);
      setState(() {}); // refresh UI
    }
  }

  void _nextExercise() {
    final exercises = _workout!.exercises;
    if (_currentExerciseIndex < exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSeriesIndex = 0;
      });
      _syncWeightField();
      // Report progress even when skipping — keeps backend in sync.
      _sendProgress(exercises.length);
    }
  }

  void _prevExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSeriesIndex = 0;
      });
      _syncWeightField();
    }
  }

  // ── Finish workout ────────────────────────────────────────────────────────

  Future<void> _onFimPressed() async {
    final bool isBonusSession = _session?.isBonusSession ?? false;

    // Bonus session: no points at stake — always a simple confirmation.
    if (isBonusSession) {
      final confirm =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Finalizar treino?', style: AppTypography.h3),
              content: Text(
                'Deseja encerrar o treino agora?',
                style: AppTypography.bodyMedium,
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
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirm || !mounted) return;
      _finishWorkout();
      return;
    }

    // Conditions are met if the backend confirmed it (meetsConditions) OR
    // points were already granted in a previous progress sync.
    final bool conditionsMet =
        _pointsGranted || (_session?.meetsConditions ?? false);

    if (!conditionsMet) {
      final shouldLeave =
          await showDialog<bool>(
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
                    'Continuar',
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
                  child: const Text('Sair mesmo assim'),
                ),
              ],
            ),
          ) ??
          false;
      if (!shouldLeave || !mounted) return;
    } else {
      final confirm =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Finalizar treino?', style: AppTypography.h3),
              content: Text(
                'Deseja encerrar o treino agora?',
                style: AppTypography.bodyMedium,
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
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirm || !mounted) return;
    }
    _finishWorkout();
  }

  Future<void> _finishWorkout() async {
    setState(() => _isFinishing = true);
    _elapsedTimer?.cancel();
    try {
      // 1. Mandatory progress sync — backend must have the latest value before
      //    evaluating point eligibility on finish.
      final total = _workout!.exercises.length;
      final best = _completedExercises > _currentExerciseIndex
          ? _completedExercises
          : _currentExerciseIndex;
      final syncProgress = ((best / total) * 100).round().clamp(0, 100);
      await _workoutService.updateProgress(syncProgress);

      // 2. Finish the session.
      final finishSession = await _workoutService.finishWorkout();

      // 3. Refetch for authoritative state (meets_conditions, points_granted).
      WorkoutSessionData status = finishSession;
      try {
        final refreshed = await _workoutService.getStatus();
        if (refreshed != null) status = refreshed;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _session = status;
        _pointsGranted = status.pointsGranted;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      // Network / server error — restore state, stay on screen, offer retry.
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
            onPressed: _finishWorkout,
          ),
        ),
      );
      return;
    }
    if (mounted) {
      final bool isBonusSession = _session?.isBonusSession ?? false;
      final bool pointsGranted = _session?.pointsGranted ?? false;
      final String message = (!isBonusSession && pointsGranted)
          ? 'Parabéns! Você ganhou 10 pontos.'
          : 'Treino finalizado ✅';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          backgroundColor: (!isBonusSession && pointsGranted)
              ? AppColors.accent
              : null,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    }
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
    } else if (_session?.isBonusSession ?? false) {
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

  // ── Helpers ───────────────────────────────────────────────────────────────

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
            _buildBottomDock(exercises, totalSeries),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: _handlePopAttempt,
          ),
          Text(
            'Execução',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const Spacer(),
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
          const SizedBox(width: 4),
          Text(
            _elapsedFormatted,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
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
            'Seus 10 pontos já estão garantidos.',
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
    if (_session!.isBonusSession) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: Colors.orange.withValues(alpha: 0.08),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Treino extra · sem pontos hoje',
              style: AppTypography.caption.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
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

  // ── Exercise card ─────────────────────────────────────────────────────────

  Widget _buildExerciseCard(
    ExerciseModel exercise,
    int totalSeries,
    int totalExercises,
  ) {
    final restTime = exercise.rest;
    final repsLabel = exercise.reps.toString();
    final cargaLabel = _weightController.text.isNotEmpty
        ? '${_weightController.text} kg'
        : '–';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
          // ── Name & metadata ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                Text(
                  exercise.name,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Séries: $totalSeries',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 1,
                          height: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      Text(
                        'Descanso: ${restTime}s',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Illustration placeholder ─────────────────────────────────────
          Container(
            height: 150,
            width: double.infinity,
            color: AppColors.background,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 52,
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Series dots ──────────────────────────────────────────────────
          _buildSeriesDots(totalSeries),

          const SizedBox(height: 20),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        repsLabel,
                        style: AppTypography.h2.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Repetições ou tempo',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        cargaLabel,
                        style: AppTypography.h2.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Carga ou Velocidade',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Info chips ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildInfoChip(Icons.play_circle_outline_rounded, 'Execução'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.sports_rounded, 'Músculos'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.open_in_full_rounded, 'Ampliar'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Alterar carga ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: OutlinedButton.icon(
              onPressed: _showAlterarCargaDialog,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Alterar carga'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Series dots ───────────────────────────────────────────────────────────

  Widget _buildSeriesDots(int totalSeries) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSeries, (index) {
        final isCurrent = index == _currentSeriesIndex;
        final isDone = index < _currentSeriesIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isCurrent ? 42 : 36,
          height: isCurrent ? 42 : 36,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary
                : isDone
                ? AppColors.accent
                : AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary
                  : isDone
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '${index + 1}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isCurrent ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  // ── Info chip ─────────────────────────────────────────────────────────────

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: AppColors.textSecondary,
        ),
        icon: Icon(icon, size: 15),
        label: Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
      ),
    );
  }

  // ── Alterar carga dialog ──────────────────────────────────────────────────

  void _showAlterarCargaDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Alterar carga', style: AppTypography.h3),
        content: TextField(
          controller: _weightController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Carga (kg)',
            hintText: '0.0',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _saveWeight();
              setState(() {});
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ── Bottom dock ───────────────────────────────────────────────────────────

  Widget _buildBottomDock(List<ExerciseModel> exercises, int totalSeries) {
    final canGoPrev = _currentExerciseIndex > 0;
    final canGoNext = _currentExerciseIndex < exercises.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 16,
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
      ),
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
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : isCurrent
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTypography.caption.copyWith(
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  ex.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
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
