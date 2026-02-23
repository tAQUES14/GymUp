import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../home/widgets/daily_workout_card.dart';
import '../services/firestore_service.dart';
import 'mocks/workouts_mock.dart';
import 'models/workout_model.dart';

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Treinos'),
      backgroundColor: AppColors.background,
      // StreamBuilder no doc do aluno — fonte de verdade para validação
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getAlunoStream(),
        builder: (context, snapshot) {
          final data = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          // Verificação síncrona — sem nova leitura do Firestore no clique.
          // Verdadeiro se validou QR hoje OU se já fez checkin hoje.
          final validouHoje =
              firestoreService.qrValidadoHoje(data) ||
              firestoreService.checkinHoje(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Treino do Dia
                DailyWorkoutCard(
                  workoutName: WorkoutsMock.standardWorkouts[0].nome,
                  duration: WorkoutsMock.standardWorkouts[0].duracao,
                  level: WorkoutsMock.standardWorkouts[0].nivel,
                  onTap: () => _onTapWorkout(
                    context,
                    WorkoutsMock.standardWorkouts[0],
                    validouHoje,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Treinos Padrão
                Text('Treinos Padrão', style: AppTypography.h3),
                const SizedBox(height: 12),
                ...WorkoutsMock.standardWorkouts.map((workout) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildWorkoutCard(context, workout, validouHoje),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Lógica de navegação ───────────────────────────────────────────────────

  /// Usa [validouHoje] derivado do StreamBuilder — sem nova leitura no clique.
  void _onTapWorkout(
    BuildContext context,
    WorkoutModel workout,
    bool validouHoje,
  ) {
    if (validouHoje) {
      Navigator.pushNamed(context, '/workout-detail', arguments: workout);
    } else {
      _showValidacaoModal(context, workout);
    }
  }

  void _showValidacaoModal(BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Valide sua presença', style: AppTypography.h3),
        content: Text(
          'Para ganhar pontos, valide o QR Code da academia antes de iniciar o treino.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Treinar sem pontos: navega direto sem validar
              Navigator.pushNamed(
                context,
                '/workout-detail',
                arguments: workout,
              );
            },
            child: Text(
              'Treinar sem pontos',
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/checkin');
            },
            child: const Text('Validar agora'),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildWorkoutCard(
    BuildContext context,
    WorkoutModel workout,
    bool validouHoje,
  ) {
    return GymUpCard(
      onTap: () => _onTapWorkout(context, workout, validouHoje),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.nome,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.nivel} • ${workout.duracao}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
