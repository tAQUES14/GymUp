import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../services/firestore_service.dart';
import 'models/workout_model.dart';
import '../../core/constants/app_config.dart';
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
  // Indices
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;

  // Workout timer
  Timer? _workoutTimer;
  final ValueNotifier<Duration> _elapsedTime = ValueNotifier(Duration.zero);

  // Rest state
  final ValueNotifier<bool> _isResting = ValueNotifier<bool>(false);
  final ValueNotifier<int> _restSecondsLeft = ValueNotifier<int>(0);
  final ValueNotifier<int> _restTotalSeconds = ValueNotifier<int>(0);
  Timer? _restTimer;

  // Checkin state (carregado no initState)
  bool _qrValidado = false;
  bool _jaRegistrouPresencaHoje = false;
  bool _isLoadingCheckinStatus = true;

  // UI colors
  static const _bgPage = AppColors.background;
  static const _bgCard = Colors.white;
  static const _textStrong = Color(0xFF111827);
  static const _textMuted = Color(0xFF6B7280);
  static const _accentPurple = AppColors.primary;
  static const _successGreen = Color(0xFF34D399);
  static const _pillBg = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.workout.exercicios.isEmpty) {
        _showEmptyWorkoutDialog();
      } else {
        _ensureCurrentExerciseHasSets();
      }
    });
    _startWorkoutTimer();
    _checkPresencaStatus();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _elapsedTime.dispose();
    _isResting.dispose();
    _restSecondsLeft.dispose();
    _restTotalSeconds.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedTime.value = _elapsedTime.value + const Duration(seconds: 1);
    });
  }

  Future<void> _checkPresencaStatus() async {
    final firestoreService = context.read<FirestoreService>();
    try {
      final qrOk = await firestoreService.verificarValidacaoHoje();
      final jaTreinou = await firestoreService.verificarCheckinHoje();
      if (mounted) {
        setState(() {
          _qrValidado = qrOk;
          _jaRegistrouPresencaHoje = jaTreinou;
          _isLoadingCheckinStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCheckinStatus = false);
    }
  }

  /// true quando o treino atual pode gerar presença com pontos.
  bool get _vaiPontuar => _qrValidado && !_jaRegistrouPresencaHoje;

  /// Total de sets marcados como concluídos em todos os exercícios.
  int get _totalSetsConcluidos {
    int total = 0;
    for (final ex in widget.workout.exercicios) {
      total += ex.sets.where((s) => s.isCompleted).length;
    }
    return total;
  }

  /// Total de sets cadastrados em todos os exercícios.
  int get _totalSetsGlobal {
    int total = 0;
    for (final ex in widget.workout.exercicios) {
      total += ex.sets.length;
    }
    return total;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSeconds(int s) {
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // Helpers
  ExerciseModel get _currentExercise {
    final list = widget.workout.exercicios;
    if (list.isEmpty) {
      return ExerciseModel(
        nome: 'Sem exercícios',
        descricao: '',
        carga: 0,
        tempoDescanso: 0,
        sets: [],
      );
    }
    _currentExerciseIndex = _currentExerciseIndex.clamp(0, list.length - 1);
    return list[_currentExerciseIndex];
  }

  int get _totalSets => _currentExercise.sets.length;

  WorkoutSet get _currentSet {
    final sets = _currentExercise.sets;
    if (sets.isEmpty) {
      return WorkoutSet(number: 1, weight: 0, reps: 0);
    }
    _currentSetIndex = _currentSetIndex.clamp(0, sets.length - 1);
    return sets[_currentSetIndex];
  }

  int get _totalExercises => widget.workout.exercicios.length;

  String get _exerciseProgressLabel {
    if (_totalExercises == 0) return 'Exercício 0/0';
    return 'Exercício ${_currentExerciseIndex + 1}/$_totalExercises';
  }

  String get _setProgressLabel {
    if (_totalSets == 0) return 'Série 0/0';
    return 'Série ${_currentSetIndex + 1}/$_totalSets';
  }

  void _ensureCurrentExerciseHasSets() {
    if (_currentExercise.sets.isEmpty) {
      _currentExercise.sets.addAll(
        List.generate(
          3,
          (i) => WorkoutSet(
            number: i + 1,
            weight: _currentExercise.carga,
            reps: 12,
          ),
        ),
      );
    }
  }

  // Flow actions
  void _onMarkDonePressed() {
    if (_isResting.value) return;

    HapticFeedback.lightImpact();

    setState(() {
      if (_currentExercise.sets.isNotEmpty &&
          _currentSetIndex < _currentExercise.sets.length) {
        _currentExercise.sets[_currentSetIndex].isCompleted = true;
      }
    });

    final rest = _currentExercise.tempoDescanso;
    if (rest > 0) {
      _startRest(rest);
    } else {
      _advanceAfterSet();
    }
  }

  void _advanceAfterSet() {
    if (_isResting.value) {
      _stopRest();
    }

    if (_totalSets == 0) {
      _nextExercise();
      return;
    }

    if (_currentSetIndex < _totalSets - 1) {
      setState(() => _currentSetIndex++);
    } else {
      _nextExercise();
    }
  }

  void _nextExercise() {
    if (_totalExercises == 0) return;

    if (_currentExerciseIndex < _totalExercises - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      });
      _ensureCurrentExerciseHasSets();
    } else {
      _finishWorkout();
    }
  }

  void _prevExercise() {
    if (_totalExercises == 0) return;

    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSetIndex = 0;
      });
      _ensureCurrentExerciseHasSets();
    }
  }

  // Rest logic
  void _startRest(int seconds) {
    _restTimer?.cancel();

    _isResting.value = true;
    _restTotalSeconds.value = seconds;
    _restSecondsLeft.value = seconds;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final currentLeft = _restSecondsLeft.value;

      if (currentLeft <= 1) {
        t.cancel();
        _advanceAfterSet();
      } else {
        _restSecondsLeft.value = currentLeft - 1;
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    _restTimer = null;

    _isResting.value = false;
    _restSecondsLeft.value = 0;
    _restTotalSeconds.value = 0;
  }

  void _skipRest() {
    if (!_isResting.value) return;
    HapticFeedback.mediumImpact();
    _advanceAfterSet();
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do treino?'),
        content: const Text(
          'Se você sair agora, o progresso desta execução pode não ser salvo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: _accentPurple)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _finishWorkout() async {
    final firestoreService = context.read<FirestoreService>();
    final duracaoMinutos = _elapsedTime.value.inMinutes;
    final concluidos = _totalSetsConcluidos;
    final total = _totalSetsGlobal;

    // Cenários B, C, D — sem QR validado ou já registrou hoje
    if (!_vaiPontuar) {
      final String reason;
      if (_jaRegistrouPresencaHoje) {
        reason =
            'Você já registrou presença hoje. Apenas 1 presença por dia é permitida.';
      } else {
        reason = 'O QR code não foi validado antes do início do treino.';
      }
      _showFinishWithoutPointsSheet(
        reason: reason,
        duracaoMinutos: duracaoMinutos,
        concluidos: concluidos,
        total: total,
      );
      return;
    }

    // Cenário A — verificar condições mínimas

    // 1) Tempo mínimo de treino
    if (duracaoMinutos < kMinTrainingMinutes) {
      final confirm = await _showContinueOrFinishDialog(
        'Você treinou ${duracaoMinutos}min. '
        'Mínimo para pontuar: ${kMinTrainingMinutes}min.',
      );
      if (!mounted) return;
      if (confirm == null) return; // usuário optou por continuar treinando
      try {
        await firestoreService.saveHistoricoTreino(
          treinoId: widget.workout.id,
          treinoNome: widget.workout.nome,
          duracaoMinutos: duracaoMinutos,
          setsConcluidos: concluidos,
          setsTotais: total,
          pontosGanhos: 0,
          comCheckin: true,
        );
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    // 2) Mínimo de 50% dos sets concluídos
    final percentual = total > 0 ? (concluidos / total * 100).round() : 0;
    if (percentual < 50) {
      final confirm = await _showContinueOrFinishDialog(
        'Você completou $percentual% dos sets. '
        'Mínimo para pontuar: 50%.',
      );
      if (!mounted) return;
      if (confirm == null) return; // usuário optou por continuar treinando
      try {
        await firestoreService.saveHistoricoTreino(
          treinoId: widget.workout.id,
          treinoNome: widget.workout.nome,
          duracaoMinutos: duracaoMinutos,
          setsConcluidos: concluidos,
          setsTotais: total,
          pontosGanhos: 0,
          comCheckin: true,
        );
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    // 3) Todas as condições atendidas — registrar presença (+10 pts)
    try {
      await firestoreService.registrarPresenca();
      await firestoreService.saveHistoricoTreino(
        treinoId: widget.workout.id,
        treinoNome: widget.workout.nome,
        duracaoMinutos: duracaoMinutos,
        setsConcluidos: concluidos,
        setsTotais: total,
        pontosGanhos: 10,
        comCheckin: true,
      );

      final alunoDoc = await firestoreService.getAluno();
      final alunoData = alunoDoc.data() as Map<String, dynamic>?;
      final streak = (alunoData?['streak'] as num?)?.toInt() ?? 1;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutCompletePage(
            workoutNome: widget.workout.nome,
            duracaoMinutos: duracaoMinutos,
            setsConcluidos: concluidos,
            setsTotais: total,
            streak: streak,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _showFinishWithoutPointsSheet(
        reason: msg,
        duracaoMinutos: duracaoMinutos,
        concluidos: concluidos,
        total: total,
      );
    }
  }

  /// Bottom sheet exibido quando o treino finaliza sem pontos (cenários B/C/D
  /// ou quando o usuário confirma finalização antecipada).
  void _showFinishWithoutPointsSheet({
    required String reason,
    required int duracaoMinutos,
    required int concluidos,
    required int total,
  }) {
    final firestoreService = context.read<FirestoreService>();
    final qrValidado = _qrValidado;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 56, color: _accentPurple),
            const SizedBox(height: 16),
            const Text(
              'Treino finalizado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _textStrong,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este treino não gerou pontos.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  try {
                    await firestoreService.saveHistoricoTreino(
                      treinoId: widget.workout.id,
                      treinoNome: widget.workout.nome,
                      duracaoMinutos: duracaoMinutos,
                      setsConcluidos: concluidos,
                      setsTotais: total,
                      pontosGanhos: 0,
                      comCheckin: qrValidado,
                    );
                  } catch (_) {}
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  );
                },
                child: const Text('Ok, voltar ao início'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo de confirmação quando uma condição mínima não foi atingida.
  /// Retorna [true] para finalizar sem pontos, [null] para continuar.
  Future<bool?> _showContinueOrFinishDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Finalizar sem pontos?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar treinando'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar sem pontos'),
          ),
        ],
      ),
    );
  }

  void _showEmptyWorkoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Treino sem exercícios'),
        content: const Text(
          'Esse treino não possui exercícios cadastrados. Volte e gere/edite um treino válido.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  // Load editing
  void _changeLoad() {
    if (_totalSets == 0) return;

    double temp = (_currentSet.weight > 0) ? _currentSet.weight : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Alterar carga',
                  style: AppTypography.h3.copyWith(color: _textStrong),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina a carga para ${_currentExercise.nome}.',
                  style: const TextStyle(color: _textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                StatefulBuilder(
                  builder: (ctx, setModalState) {
                    void inc() => setModalState(() => temp += 2.5);
                    void dec() =>
                        setModalState(() => temp = (temp - 2.5).clamp(0, 999));

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _pillBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: dec,
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            temp == 0 ? '—' : '${temp.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _textStrong,
                            ),
                          ),
                          IconButton(
                            onPressed: inc,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentSet.weight = temp;
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Aplicar na série atual'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (final s in _currentExercise.sets) {
                              s.weight = temp;
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Aplicar em todas'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openListBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final exs = widget.workout.exercicios;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lista de exercícios',
                  style: AppTypography.h3.copyWith(color: _textStrong),
                ),
                const SizedBox(height: 12),
                if (exs.isEmpty)
                  const Text('Nenhum exercício.')
                else
                  ...List.generate(exs.length, (i) {
                    final isActive = i == _currentExerciseIndex;
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentExerciseIndex = i;
                          _currentSetIndex = 0;
                        });
                        _ensureCurrentExerciseHasSets();
                      },
                      title: Text(
                        exs[i].nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isActive ? _accentPurple : _textStrong,
                        ),
                      ),
                      subtitle: Text(
                        'Séries: ${exs[i].sets.length} • Descanso: ${exs[i].tempoDescanso}s',
                        style: const TextStyle(color: _textMuted),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.play_arrow, color: _accentPurple)
                          : null,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Banner de status de presença ──────────────────────────────────────────

  Widget _buildPresencaBanner() {
    if (_isLoadingCheckinStatus) return const SizedBox.shrink();

    // Cenário C / D — já registrou presença hoje
    if (_jaRegistrouPresencaHoje) {
      return _bannerTile(
        bgColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF90CAF9),
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF1565C0),
        text: 'Presença já registrada hoje • Treino livre sem pontos',
      );
    }

    // Cenário A — QR validado, vai pontuar
    if (_qrValidado) {
      return _bannerTile(
        bgColor: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFF81C784),
        icon: Icons.check_circle,
        iconColor: const Color(0xFF2E7D32),
        text: '✓ Check-in validado • Treino conta para presença',
      );
    }

    // Cenário B — sem QR
    return _bannerTile(
      bgColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFCA28),
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFE65100),
      text: '⚠ Sem check-in • Este treino não contará para presença',
      linkText: 'Validar agora',
      onLinkTap: () async {
        await Navigator.pushNamed(context, '/checkin');
        _checkPresencaStatus();
      },
    );
  }

  Widget _bannerTile({
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String text,
    String? linkText,
    VoidCallback? onLinkTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
          if (linkText != null && onLinkTap != null)
            GestureDetector(
              onTap: onLinkTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  linkText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = (screenHeight * 0.33).clamp(190.0, 230.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (ok && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bgPage,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // NÃO bloqueia a tela no descanso (você pediu isso)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, panelHeight + 28),
                child: Column(
                  children: [
                    if (!_isLoadingCheckinStatus) ...[
                      _buildPresencaBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildMainCard(),
                    const SizedBox(height: 16),
                    _buildChangeLoadButton(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomControlPanel(panelHeight),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _accentPurple,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final ok = await _confirmExit();
          if (ok && mounted) Navigator.of(context).pop();
        },
      ),
      title: Text(
        'Execução',
        style: AppTypography.h3.copyWith(color: Colors.white),
      ),
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                ValueListenableBuilder<Duration>(
                  valueListenable: _elapsedTime,
                  builder: (_, d, _) {
                    return Text(
                      _formatDuration(d),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    final hasSets = _totalSets > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallPill(_exerciseProgressLabel),
              _smallPill(_setProgressLabel),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _currentExercise.nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(
              color: _textStrong,
              fontSize: 22,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _pillBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Séries: $_totalSets | Descanso: ${_currentExercise.tempoDescanso}s',
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _bgPage,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: _accentPurple.withValues(alpha: 0.28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (hasSets)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalSets, (index) {
                final isCurrent = index == _currentSetIndex;
                final isCompleted = _currentExercise.sets[index].isCompleted;

                Color color;
                if (isCurrent && !isCompleted) {
                  color = _accentPurple;
                } else if (isCompleted) {
                  color = _successGreen;
                } else {
                  color = const Color(0xFFE5E7EB);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isCurrent ? 22 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            )
          else
            const Text(
              'Sem séries configuradas.',
              style: TextStyle(color: _textMuted),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildDataBlock(
                'Repetições',
                hasSets ? '${_currentSet.reps}' : '—',
              ),
              const SizedBox(width: 14),
              _buildDataBlock(
                'Carga (kg)',
                hasSets && _currentSet.weight > 0
                    ? _currentSet.weight.toStringAsFixed(1)
                    : '—',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryAction(Icons.play_circle_outline, 'Execução'),
              _buildSecondaryAction(Icons.boy_outlined, 'Músculos'),
              _buildSecondaryAction(Icons.zoom_in, 'Ampliar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDataBlock(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                color: _textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryAction(IconData icon, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label (em breve)'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeLoadButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _changeLoad,
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text('Alterar Carga'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          foregroundColor: _textStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  // Bottom panel (ajustado como você pediu)
  Widget _buildBottomControlPanel(double panelHeight) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPad = (safeBottom + 14).clamp(14.0, 34.0);

    return SizedBox(
      height: panelHeight,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isResting,
        builder: (_, resting, _) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _accentPurple.withValues(alpha: 0.95),
                  _accentPurple.withValues(alpha: 1.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
              child: Column(
                children: [
                  // Row superior: setas + centro (timer ou realizado grande)
                  Row(
                    children: [
                      _roundIcon(
                        icon: Icons.skip_previous_rounded,
                        onTap: resting ? null : _prevExercise,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: resting
                                ? _buildRestPill()
                                : _buildDoneBigButton(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      _roundIcon(
                        icon: Icons.skip_next_rounded,
                        onTap: resting ? null : _nextExercise,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pular descanso menor (não full width)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: resting
                        ? Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton(
                                onPressed: _skipRest,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.30),
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Pular descanso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 38),
                  ),

                  const Spacer(),

                  // Footer: lista / fim
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _openListBottomSheet,
                        icon: const Icon(Icons.list, color: Colors.white70),
                        tooltip: 'Lista de Exercícios',
                      ),
                      TextButton(
                        onPressed: _finishWorkout,
                        child: const Text(
                          'FIM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestPill() {
    // Timer maior (você pediu)
    return ValueListenableBuilder<int>(
      valueListenable: _restSecondsLeft,
      builder: (_, left, _) {
        return ValueListenableBuilder<int>(
          valueListenable: _restTotalSeconds,
          builder: (_, total, _) {
            final totalText = total <= 0 ? '--:--' : _formatSeconds(total);

            return Container(
              key: const ValueKey('rest-pill'),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // bolinha com número (mais forte)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentPurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      // número bem grande
                      '$left',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _accentPurple,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descanso',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _textStrong,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'de $totalText',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoneBigButton() {
    // Realizado grandão, branco, bem visível (você pediu)
    return SizedBox(
      key: const ValueKey('done-big'),
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _onMarkDonePressed,
        icon: const Icon(Icons.check_rounded, size: 22),
        label: const Text(
          'Realizado',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _accentPurple,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.06),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.40),
          size: 28,
        ),
      ),
    );
  }
}
