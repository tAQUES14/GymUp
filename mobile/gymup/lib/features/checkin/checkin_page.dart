import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/models/workout_plan_model.dart';
import '../workouts/workout_api_service.dart';
import '../workouts/workout_plan_api_service.dart';
import '../workouts/workout_plan_utils.dart';
import 'checkin_api_service.dart';
import 'qr_service.dart';

enum _CheckinState { scanning, success, error }

class CheckinPageArgs {
  final WorkoutModel? workout;
  final bool isRestDayWorkout;

  const CheckinPageArgs({
    this.workout,
    this.isRestDayWorkout = false,
  });
}

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );
  final TextEditingController _manualController = TextEditingController();
  final QrService _qrService = QrService();
  final CheckinApiService _checkinService = CheckinApiService();
  final WorkoutApiService _workoutService = WorkoutApiService();

  bool _isProcessing = false;
  bool _handledScan = false;
  bool _didReadArgs = false;
  bool _didPrepareScanner = false;
  bool _scannerActive = false;
  bool _scannerRunning = false;
  Future<void> _scannerOp = Future<void>.value();
  bool _disposed = false;
  _CheckinState _state = _CheckinState.scanning;
  WorkoutModel? _argumentWorkout;
  WorkoutModel? _validatedWorkout;
  WorkoutSessionData? _validatedSession;
  bool _isRestDayFlow = false;
  String _errorTitle = 'QR Code invalido';
  String _errorMessage =
      'Nao foi possivel validar este codigo.\nVerifique se voce esta na academia correta\nou tente novamente.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state != _CheckinState.scanning) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_startScanner());
    } else {
      unawaited(_stopScanner());
    }
  }

  @override
  void deactivate() {
    unawaited(_stopScanner());
    super.deactivate();
  }

  Future<void> _startScanner() async {
    if (_disposed || _scannerActive || _state != _CheckinState.scanning) return;
    _scannerOp = _scannerOp.then((_) async {
      if (_disposed || _scannerRunning || _state != _CheckinState.scanning) return;
      if (mounted) {
        setState(() => _scannerActive = true);
      }
      try {
        await _scannerController.start();
        _scannerRunning = true;
      } catch (_) {
        _scannerRunning = false;
        if (mounted) setState(() => _scannerActive = false);
      }
    });
    await _scannerOp;
  }

  Future<void> _stopScanner() async {
    _scannerOp = _scannerOp.then((_) async {
      if (!_scannerRunning) {
        if (mounted && !_disposed && _scannerActive) {
          setState(() => _scannerActive = false);
        } else {
          _scannerActive = false;
        }
        return;
      }

      try {
        await _scannerController.stop();
      } catch (_) {}
      _scannerRunning = false;
      if (mounted && !_disposed) {
        setState(() => _scannerActive = false);
      } else {
        _scannerActive = false;
      }
    });
    await _scannerOp;
  }

  void _forceScannerInactive() {
    _scannerRunning = false;
    if (mounted && !_disposed) {
      setState(() => _scannerActive = false);
    } else {
      _scannerActive = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WorkoutModel) {
      _argumentWorkout = args;
    } else if (args is CheckinPageArgs) {
      _argumentWorkout = args.workout;
      _isRestDayFlow = args.isRestDayWorkout;
    }
    unawaited(_prepareScanner());
  }

  Future<void> _prepareScanner() async {
    if (_didPrepareScanner || _disposed) return;
    _didPrepareScanner = true;

    if (_argumentWorkout == null) {
      try {
        final results = await Future.wait([
          WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
          _workoutService.getWorkouts().catchError((_) => <WorkoutModel>[]),
        ]);
        if (!mounted || _disposed) return;
        final plan = results[0] as TodayWorkoutPlan?;
        final workouts = results[1] as List<WorkoutModel>;
        final workout = _resolveWorkout(plan, workouts);
        if (workout == null) {
          _showInvalidState(
            title: 'Você ainda não tem nenhum treino',
            message:
                'Para liberar o QR Code, você precisa ter ao menos um treino criado ou um treino indicado no seu plano.',
          );
          return;
        }
      } catch (_) {
        if (!mounted || _disposed) return;
      }
    }

    await _ensureCameraPermission();
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      unawaited(_startScanner());
      return;
    }
    if (status.isPermanentlyDenied) {
      _showPermissionDialog(permanent: true);
    } else {
      _showPermissionDialog(permanent: false);
    }
  }

  void _showPermissionDialog({required bool permanent}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Permissao de camera'),
        content: Text(
          permanent
              ? 'A permissao de camera foi negada permanentemente. Acesse as configuracoes do app para habilita-la.'
              : 'O GymUp precisa da camera para escanear o QR Code da academia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (permanent) openAppSettings();
            },
            child: Text(permanent ? 'Abrir configuracoes' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan || _isProcessing || _state != _CheckinState.scanning) {
      return;
    }
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _handledScan = true;
    unawaited(_handleDetectedCode(code));
  }

  Future<void> _handleDetectedCode(String code) async {
    await _stopScanner();
    if (!mounted || _disposed) return;
    await _processCheckin(code, fromCamera: true);
  }

  void _resetScanner() {
    setState(() {
      _state = _CheckinState.scanning;
      _isProcessing = false;
      _handledScan = false;
      _validatedWorkout = null;
      _validatedSession = null;
    });
    unawaited(_startScanner());
  }

  Future<void> _submitManual() async {
    final code = _manualController.text.trim();
    if (code.isEmpty) return;
    Navigator.of(context).maybePop();
    await _processCheckin(code, fromCamera: false);
  }

  Future<void> _processCheckin(String code, {required bool fromCamera}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (!_qrService.isValidQr(code)) {
      _showInvalidState(
        title: 'QR Code invalido',
        message:
            'Nao foi possivel validar este codigo.\nVerifique se voce esta na academia correta\nou tente novamente.',
      );
      return;
    }

    try {
      final results = await Future.wait([
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
        _workoutService.getWorkouts().catchError((_) => <WorkoutModel>[]),
      ]);
      if (!mounted) return;

      final plan = results[0] as TodayWorkoutPlan?;
      final workouts = results[1] as List<WorkoutModel>;
      final workout = _argumentWorkout ?? _resolveWorkout(plan, workouts);

      if (workout == null) {
        _showInvalidState(
          title: 'Voce ainda nao tem nenhum treino',
          message:
              'Para liberar o QR Code, voce precisa ter ao menos um treino criado ou um treino indicado no seu plano.',
        );
        return;
      }

      await _checkinService.doCheckIn(qrToken: code);
      if (!mounted) return;

      WorkoutSessionData? session;
      session = await _workoutService.startWorkout();
      if (!mounted) return;

      setState(() {
        _validatedWorkout = workout;
        _validatedSession = session;
        _state = _CheckinState.success;
        _isProcessing = false;
      });
      unawaited(_stopScanner());
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');

      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (msg == '409') {
        await _handleAlreadyCheckedIn();
        return;
      }

      _showInvalidState(
        title: msg == '403' ? 'QR Code invalido' : 'Nao foi possivel validar',
        message: msg == '403'
            ? 'Nao foi possivel validar este codigo.\nVerifique se voce esta na academia correta\nou tente novamente.'
            : 'Tivemos um problema ao validar seu check-in.\nVerifique sua conexao e tente novamente.',
      );
    }
  }

  Future<void> _handleAlreadyCheckedIn() async {
    try {
      final results = await Future.wait([
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
        _workoutService.getWorkouts().catchError((_) => <WorkoutModel>[]),
      ]);
      if (!mounted) return;
      final plan = results[0] as TodayWorkoutPlan?;
      final workouts = results[1] as List<WorkoutModel>;
      final workout = _argumentWorkout ?? _resolveWorkout(plan, workouts);
      if (workout == null) {
        _showInvalidState(
          title: 'Voce ainda nao tem nenhum treino',
          message:
              'Seu check-in ja foi registrado, mas voce precisa ter ao menos um treino criado ou indicado no plano para iniciar.',
        );
        return;
      }
      setState(() {
        _validatedWorkout = workout;
        _validatedSession = null;
        _state = _CheckinState.success;
        _isProcessing = false;
      });
      unawaited(_stopScanner());
    } catch (_) {
      _showInvalidState(
        title: 'Nao foi possivel validar',
        message: 'Tivemos um problema ao recuperar seu treino.\nTente novamente.',
      );
    }
  }

  void _showInvalidState({required String title, required String message}) {
    if (!mounted) return;
    setState(() {
      _errorTitle = title;
      _errorMessage = message;
      _state = _CheckinState.error;
      _isProcessing = false;
      _handledScan = false;
    });
    unawaited(_stopScanner());
  }

  WorkoutModel? _resolveWorkout(TodayWorkoutPlan? plan, List<WorkoutModel> workouts) {
    if (plan != null && !plan.isRestDay && plan.today.exercises.isNotEmpty) {
      return workoutFromPlan(plan);
    }
    if (workouts.isNotEmpty) return workouts.first;
    return null;
  }

  String _successDescription() {
    final session = _validatedSession;
    if (session != null && session.dailyPointsAlreadyGranted) {
      return _isRestDayFlow
          ? 'Voce ja ganhou seus pontos hoje. Esse treino livre nao gera pontos, mas pode ser registrado.'
          : 'Voce ja ganhou seus pontos hoje. Este treino extra nao gera pontos.';
    }
    if (_isRestDayFlow) {
      return 'Hoje nao ha treino obrigatorio. Seu streak esta protegido; se concluir um treino valido, ele pode gerar pontos.';
    }
    if (session == null) return 'Seu check-in foi validado com sucesso.';
    return 'Seu check-in foi validado com sucesso.';
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _forceScannerInactive();
    final controller = _scannerController;
    unawaited(
      _scannerOp
          .then((_) => controller.stop())
          .catchError((_) {})
          .whenComplete(controller.dispose),
    );
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: _state == _CheckinState.scanning
            ? const Color(0xFF0E1116)
            : const Color(0xFFF3F5F9),
        body: switch (_state) {
          _CheckinState.scanning => _buildScanner(),
          _CheckinState.success => _buildSuccess(),
          _CheckinState.error => _buildError(),
        },
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_scannerActive)
          MobileScanner(controller: _scannerController, onDetect: _onDetect)
        else
          Container(color: const Color(0xFF0E1116)),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.50, 0.45),
              radius: 0.70,
              colors: [Color(0x661A1D24), Color(0xCC0E1116)],
            ),
          ),
        ),
        CustomPaint(painter: _CheckinScannerOverlayPainter()),
        SafeArea(
          child: Column(
            children: [
              _buildScannerHeader(),
              const Spacer(),
              _buildWaitingBadge(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'A leitura acontece automaticamente assim que o\ncodigo for reconhecido.',
                  textAlign: TextAlign.center,
                  style: AppText.pjs(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              _buildManualEntryButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.28),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8F84A)),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.arrow_back_rounded,
            color: Colors.white.withValues(alpha: 0.12),
            iconColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.16),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in',
                  style: AppText.pjs(
                    size: 17,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.05,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Aponte para o QR Code da academia',
                  style: AppText.pjs(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildWaitingBadge() {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 14, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.70),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AGUARDANDO LEITURA...',
            style: AppText.pjs(
              size: 11.5,
              weight: FontWeight.w800,
              color: const Color(0xFF0E1116),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E1116).withValues(alpha: 0.0),
            const Color(0xFF0E1116).withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: _showManualSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 7),
                Text(
                  'Nao consegue escanear? Inserir codigo',
                  style: AppText.pjs(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showManualSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x510E1116),
                  blurRadius: 60,
                  offset: Offset(0, -24),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x230E1116),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Inserir codigo',
                    style: AppText.pjs(
                      size: 20,
                      weight: FontWeight.w800,
                      color: const Color(0xFF0E1116),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use esta opcao caso a camera nao consiga ler o QR Code.',
                    style: AppText.pjs(
                      size: 13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF5B6472),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'CODIGO DA ACADEMIA',
                    style: AppText.pjs(
                      size: 11,
                      weight: FontWeight.w800,
                      color: const Color(0xFF5B6472),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Color(0xFF0E1116),
                      fontSize: 17,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'TNT-9F4K',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9AA3B0),
                        fontSize: 17,
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                      prefixIcon: const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.blue,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FC),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.blue),
                      ),
                    ),
                    onSubmitted: (_) => _submitManual(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Voce encontra o codigo na recepcao da academia.',
                    style: AppText.pjs(
                      size: 11,
                      weight: FontWeight.w500,
                      color: const Color(0xFF9AA3B0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _primaryButton(
                    label: 'Validar codigo',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _isProcessing ? null : _submitManual,
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Cancelar',
                        style: AppText.pjs(
                          size: 13,
                          weight: FontWeight.w700,
                          color: const Color(0xFF5B6472),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccess() {
    final workout = _validatedWorkout;
    return SafeArea(
      child: SizedBox.expand(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _lightHeader('Check-in validado'),
                  const SizedBox(height: 18),
                  _successHero(),
                  if (workout != null) ...[
                    const SizedBox(height: 18),
                    _workoutReadyCard(workout),
                    const SizedBox(height: 14),
                    _pointsInfoCard(),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _successBottomDock(workout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successHero() {
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.07, -0.10),
          end: Alignment(0.93, 1.10),
          colors: [Color(0xFF2F6FED), Color(0xFF4A8CFF), Color(0xFFC8F84A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8F84A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1F4FC4),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isRestDayFlow ? 'Treino livre liberado!' : 'Presença confirmada!',
                  textAlign: TextAlign.center,
                  style: AppText.pjs(
                    size: 24,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.05,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 308),
                  child: Text(
                    _successDescription(),
                    textAlign: TextAlign.center,
                    style: AppText.pjs(
                      size: 13.5,
                      weight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8F84A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1F4FC4),
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ACADEMIA AUTORIZADA',
                        style: AppText.pjs(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workoutReadyCard(WorkoutModel workout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRestDayFlow ? 'TREINO LIVRE' : 'TREINO DO DIA',
            style: AppText.pjs(
              size: 10.5,
              weight: FontWeight.w800,
              color: const Color(0xFF9AA3B0),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF2F6FED),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.pjs(
                        size: 17,
                        weight: FontWeight.w800,
                        color: const Color(0xFF0E1116),
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${workout.exercises.length} exercicios  -  ${workout.duration ?? 50} min',
                      style: AppText.pjs(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF5B6472),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDFBD3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BA300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 10),
                Text(
                  _isRestDayFlow ? 'Opcional e validado' : 'Pronto para iniciar',
                  style: AppText.pjs(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF5BA300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1E2F6FED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _isRestDayFlow
                        ? 'Dia de descanso: este treino pode gerar '
                        : 'Finalize o treino corretamente para receber\n',
                  ),
                  TextSpan(
                    text: 'pontos',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: _isRestDayFlow ? ', mas nao aumenta sua ' : ' e manter sua ',
                  ),
                  TextSpan(
                    text: 'sequencia',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: AppText.pjs(
                size: 12.5,
                weight: FontWeight.w500,
                color: const Color(0xFF0E1116),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBottomDock(WorkoutModel? workout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 26),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F9),
        border: Border(top: BorderSide(color: Color(0x0F0E1116))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (workout != null)
              _primaryButton(
                label: _isRestDayFlow ? 'Iniciar treino livre' : 'Iniciar treino',
                icon: Icons.play_arrow_rounded,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/workout-step',
                  arguments: workout,
                ),
              ),
            if (workout != null) const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Text(
                'Voltar ao inicio',
                style: AppText.pjs(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: SizedBox.expand(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _lightHeader('Check-in'),
                  const SizedBox(height: 18),
                  _errorHero(),
                  const SizedBox(height: 20),
                  Text(
                    'Possiveis motivos',
                    style: AppText.pjs(
                      size: 14,
                      weight: FontWeight.w800,
                      color: const Color(0xFF0E1116),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _reasonsCard(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _errorBottomDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 27, 23, 23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.33, -0.18),
          end: Alignment(0.67, 1.18),
          colors: [Color(0xFFFFF4E5), Color(0xFFFFEDDC)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x2DFF7A1A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x23FF7A1A),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3DFF7A1A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF7A1A),
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorTitle,
            textAlign: TextAlign.center,
            style: AppText.pjs(
              size: 22,
              weight: FontWeight.w800,
              color: const Color(0xFF0E1116),
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: AppText.pjs(
              size: 13.5,
              weight: FontWeight.w500,
              color: const Color(0xFF7A4500),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonsCard() {
    const reasons = [
      'Codigo expirado',
      'Academia diferente da sua conta',
      'Problema de conexao',
    ];

    return Container(
      width: double.infinity,
      decoration: _whiteCardDecoration(radius: 18),
      child: Column(
        children: [
          for (var i = 0; i < reasons.length; i++)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: i == reasons.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: Color(0x0C0E1116))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDDC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFFF7A1A),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reasons[i],
                      style: AppText.pjs(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF0E1116),
                        letterSpacing: -0.2,
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

  Widget _errorBottomDock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 26),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F9),
        border: Border(top: BorderSide(color: Color(0x0F0E1116))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _primaryButton(
              label: 'Tentar novamente',
              icon: Icons.refresh_rounded,
              onTap: _resetScanner,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showManualSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_rounded, color: AppColors.blue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Inserir codigo manualmente',
                    style: AppText.pjs(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.blue,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Text(
                'Voltar',
                style: AppText.pjs(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF9AA3B0),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lightHeader(String title) {
    return Row(
      children: [
        _roundIconButton(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          iconColor: const Color(0xFF0E1116),
          borderColor: const Color(0x0F0E1116),
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.pjs(
              size: 17,
              weight: FontWeight.w800,
              color: const Color(0xFF0E1116),
              height: 1.05,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.21, -1.45),
              end: Alignment(0.79, 2.45),
              colors: [Color(0xFF1F4FC4), Color(0xFF2F6FED), Color(0xFF4A8CFF)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.36),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppText.pjs(
                  size: 15.5,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _whiteCardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _CheckinScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanWidth = (size.width - 100).clamp(240.0, 290.0).toDouble();
    final scanHeight = scanWidth;
    final top = size.height * 0.24;
    final left = (size.width - scanWidth) / 2;
    final rect = Rect.fromLTWH(left, top, scanWidth, scanHeight);

    final overlayPaint = Paint()..color = const Color(0x9E0E1116);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rect.top), overlayPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, rect.bottom, size.width, size.height - rect.bottom),
      overlayPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, rect.top, rect.left, rect.height), overlayPaint);
    canvas.drawRect(
      Rect.fromLTWH(rect.right, rect.top, rect.left, rect.height),
      overlayPaint,
    );

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x002F6FED),
          Color(0xFF2F6FED),
          Color(0xFF4A8CFF),
          Color(0xFF2F6FED),
          Color(0x002F6FED),
        ],
      ).createShader(Rect.fromLTWH(rect.left + 18, rect.center.dy, rect.width - 36, 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.left + 18, rect.center.dy),
      Offset(rect.right - 18, rect.center.dy),
      linePaint,
    );

    final cornerPaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 38.0;
    void corner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, cornerPaint);
      canvas.drawLine(start, vEnd, cornerPaint);
    }

    corner(rect.topLeft, rect.topLeft + const Offset(len, 0), rect.topLeft + const Offset(0, len));
    corner(rect.topRight, rect.topRight - const Offset(len, 0), rect.topRight + const Offset(0, len));
    corner(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), rect.bottomLeft - const Offset(0, len));
    corner(rect.bottomRight, rect.bottomRight - const Offset(len, 0), rect.bottomRight - const Offset(0, len));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
