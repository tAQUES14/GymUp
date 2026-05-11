import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/models/workout_plan_model.dart';
import '../workouts/workout_api_service.dart';
import '../workouts/workout_plan_api_service.dart';
import '../workouts/workout_plan_utils.dart';
import 'checkin_api_service.dart';
import 'qr_service.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _isProcessing = false;
  final QrService _qrService = QrService();
  final CheckinApiService _checkinService = CheckinApiService();
  final WorkoutApiService _workoutService = WorkoutApiService();
  final TextEditingController _manualController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Check-in',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Card hero gradiente ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kBlue, _kBlueDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 72,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Check-in na Academia',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Escaneie o QR Code da academia\nou cole o código abaixo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Campo de texto ───────────────────────────────────────────────
            TextFormField(
              controller: _manualController,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: 'Código QR',
                labelStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.qr_code_rounded,
                  color: _kBlue,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBlue, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Chip de dica ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: _kBlue.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cole o código gerado na página da academia.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kBlue.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botão CTA ────────────────────────────────────────────────────
            GestureDetector(
              onTap: _isProcessing ? null : _processCheckin,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isProcessing ? 0.75 : 1.0,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kBlue, _kBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Validar QR Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckin() async {
    final code = _manualController.text.trim();
    if (code.isEmpty) return;

    if (!_qrService.isValidQr(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código QR inválido')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Busca plano e treinos avulsos em paralelo.
      // O check-in é válido se o usuário tem plano OU treinos avulsos.
      final results = await Future.wait([
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
        _workoutService.getWorkouts().catchError((_) => <WorkoutModel>[]),
      ]);

      if (!mounted) return;

      final plan     = results[0] as TodayWorkoutPlan?;
      final workouts = results[1] as List<WorkoutModel>;

      // Sem plano nem treinos avulsos → bloqueia
      if (plan == null && workouts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhum plano de treino ativo. Solicite ao seu personal.',
            ),
          ),
        );
        return;
      }

      // Determina o treino a executar após o check-in.
      // Prioridade: plano do dia (se não for descanso) → treino avulso → null
      final workout = _resolveWorkout(plan, workouts);

      // QR válido → registra check-in (idempotente: 409 = já feito hoje, OK).
      await _checkinService.doCheckIn(qrToken: code);

      if (!mounted) return;

      // Inicia sessão apenas se houver treino real para executar.
      WorkoutSessionData? session;
      if (workout != null) {
        session = await _workoutService.startWorkout();
        if (!mounted) return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _kBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('QR Validado', style: AppTypography.h3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_rounded,
                color: _kBlue,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _checkinMessage(plan, session),
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                workout != null ? 'Agora não' : 'OK',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (workout != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(
                    context,
                    '/workout-step',
                    arguments: workout,
                  );
                },
                child: const Text('Iniciar Treino'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceAll('Exception: ', '');

      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (msg == '403') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR Code inválido para esta academia.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
        return;
      }

      // 409 = sessão já ativa → usa plano/treino e vai para execução.
      if (msg == '409') {
        try {
          final results = await Future.wait([
            WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
            _workoutService.getWorkouts().catchError((_) => <WorkoutModel>[]),
          ]);
          if (!mounted) return;

          final plan     = results[0] as TodayWorkoutPlan?;
          final workouts = results[1] as List<WorkoutModel>;
          final workout  = _resolveWorkout(plan, workouts);

          if (workout != null) {
            Navigator.pushReplacementNamed(
              context,
              '/workout-step',
              arguments: workout,
            );
            return;
          }
        } catch (_) {}

        if (mounted) Navigator.pop(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Resolve qual WorkoutModel executar após o check-in.
  ///
  /// Prioridade:
  ///   1. Plano do dia (se não for descanso e tiver exercícios)
  ///   2. Primeiro treino avulso disponível
  ///   3. null  → check-in registrado mas sem treino para iniciar (ex: dia de descanso)
  WorkoutModel? _resolveWorkout(TodayWorkoutPlan? plan, List<WorkoutModel> workouts) {
    if (plan != null && !plan.isRestDay && plan.today.exercises.isNotEmpty) {
      return _workoutFromPlan(plan);
    }
    if (workouts.isNotEmpty) return workouts.first;
    return null;
  }

  /// Delegates to shared utility (see workout_plan_utils.dart).
  WorkoutModel _workoutFromPlan(TodayWorkoutPlan plan) => workoutFromPlan(plan);

  String _checkinMessage(TodayWorkoutPlan? plan, WorkoutSessionData? session) {
    if (session == null) {
      if (plan != null && plan.isRestDay) {
        return 'Check-in registrado! Hoje é dia de descanso no seu plano. Bom descanso!';
      }
      return 'Check-in registrado!';
    }
    return session.dailyPointsAlreadyGranted
        ? 'Você já ganhou seus pontos hoje. Este treino extra não gera pontos, mas você pode treinar normalmente.'
        : 'Conclua o treino para ganhar seus pontos!';
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }
}
