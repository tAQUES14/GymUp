import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Meu Progresso'),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPresencasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          final presencas = snapshot.data?.docs ?? [];
          final totalPresencas = presencas.length;
          // Mock calculation for "workouts completed" based on presences
          final treinosConcluidos = totalPresencas; 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(totalPresencas, treinosConcluidos),
                const SizedBox(height: 32),
                Text(
                  'Pontos nas últimas 4 semanas',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 16),
                _buildChart(),
                const SizedBox(height: 32),
                GymUpCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 48, color: AppColors.warning),
                      const SizedBox(height: 16),
                      Text(
                        'Próxima Conquista',
                        style: AppTypography.h3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete 20 treinos para ganhar o badge "Dedicado"!',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (totalPresencas % 20) / 20,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalPresencas % 20} / 20',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int presencas, int treinos) {
    return Row(
      children: [
        Expanded(
          child: GymUpCard(
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  '$presencas',
                  style: AppTypography.h1.copyWith(color: Colors.white),
                ),
                Text(
                  'Presenças',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GymUpCard(
            child: Column(
              children: [
                Text(
                  '$treinos',
                  style: AppTypography.h1.copyWith(color: AppColors.primary),
                ),
                Text(
                  'Treinos',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    // Mock data
    final data = [50, 80, 40, 100];
    final max = 100;

    return GymUpCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final value = data[index];
            final heightFactor = value / max;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heightFactor),
                  duration: const Duration(seconds: 1),
                  builder: (context, val, child) {
                    return Container(
                      width: 30,
                      height: 150 * val,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem ${index + 1}',
                  style: AppTypography.caption,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
