import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_text_field.dart';
import '../workouts/mocks/workouts_mock.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/workout_api_service.dart';
import 'qr_service.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _isProcessing = false;
  final QrService _qrService = QrService();
  final WorkoutApiService _workoutService = WorkoutApiService();
  final TextEditingController _manualController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Check-in'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            GymUpCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text('Scanner de QR Code', style: AppTypography.h2),
                  const SizedBox(height: 16),
                  Text(
                    'O Scanner de câmera não está disponível na versão Web. Utilize o código manual abaixo para simular.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GymUpTextField(
              label: 'Código do QR',
              controller: _manualController,
              suffixIcon: const Icon(Icons.keyboard),
            ),
            const SizedBox(height: 24),
            GymUpButton(
              label: 'VALIDAR QR CODE',
              isLoading: _isProcessing,
              onPressed: _processCheckin,
            ),
            const SizedBox(height: 16),
            Text('Dica: Use "GYMUP-ACADEMIA-01"', style: AppTypography.caption),
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

    // Treino selecionado pelo usuário antes do check-in, ou fallback para o padrão
    final workout =
        ModalRoute.of(context)?.settings.arguments as WorkoutModel? ??
            WorkoutsMock.standardWorkouts[0];

    try {
      // QR válido → inicia sessão de treino. Pontos serão concedidos apenas
      // após o treino ser concluído com tempo e progresso suficientes.
      final session = await _workoutService.startWorkout();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('QR Validado ✅', style: AppTypography.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_rounded,
                color: AppColors.primary,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                session.dailyPointsAlreadyGranted
                    ? 'Você já ganhou seus pontos hoje. Este treino extra não gera pontos, mas você pode treinar normalmente.'
                    : 'Conclua o treino para ganhar 10 pontos.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Agora não',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                // Substitui a página de checkin pelo treino,
                // mantendo WorkoutDetailPage na pilha para o usuário voltar
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

      // 409 = sessão já ativa → ir direto para o treino
      if (msg == '409') {
        Navigator.pushReplacementNamed(
          context,
          '/workout-step',
          arguments: workout,
        );
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

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }
}
