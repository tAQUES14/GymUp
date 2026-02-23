import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_text_field.dart';
import '../services/firestore_service.dart';
import '../workouts/mocks/workouts_mock.dart';
import 'qr_service.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _isProcessing = false;
  final QrService _qrService = QrService();
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

    if (_qrService.isValidQr(code)) {
      setState(() => _isProcessing = true);

      try {
        // Apenas valida o QR — NÃO registra presença nem concede pontos
        await context.read<FirestoreService>().validarPresencaHoje(code);
        if (mounted) {
          // Usa o treino do dia (standardWorkouts[0]) para ir direto à execução
          final dailyWorkout = WorkoutsMock.standardWorkouts[0];

          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text('QR Validado! ✅', style: AppTypography.h3),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.accent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Você está na academia! Bora treinar?',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context); // fecha checkin
                    },
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
                      Navigator.pop(context); // fecha checkin
                      // Vai direto para a execução do treino do dia
                      Navigator.pushNamed(
                        context,
                        '/workout-execution-exercise',
                        arguments: dailyWorkout,
                      );
                    },
                    child: const Text('Iniciar Treino'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Código QR inválido')));
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }
}
