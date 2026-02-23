import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';
import 'widgets/home_header.dart';
import 'widgets/points_card.dart';
import 'widgets/weekly_goal_section.dart';
import 'widgets/daily_workout_card.dart';
import 'widgets/weekly_progress_bar.dart';
import 'widgets/recent_activities_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // StreamBuilder principal: doc do aluno como fonte de verdade
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getAlunoStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final nome = data['nome'] ?? 'Aluno';
          final pontos = data['pontos'] ?? 0;
          final streak = (data['streak'] as num?)?.toInt() ?? 0;
          final photoUrl = data['photoUrl'] as String?;

          // Verificação síncrona — sem nova leitura do Firestore.
          // Verdadeiro se validou QR hoje OU se já fez checkin hoje.
          final validouOuFezCheckinHoje =
              firestoreService.qrValidadoHoje(data) ||
              firestoreService.checkinHoje(data);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(nome: nome, photoUrl: photoUrl),
                  const SizedBox(height: 24),

                  PointsCard(pontos: pontos),
                  const SizedBox(height: 24),

                  StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getPresencasStream(),
                    builder: (context, snapshotPresencas) {
                      int workoutsDone = 0;
                      final diasTreinados = <int>{};

                      if (snapshotPresencas.hasData) {
                        final now = DateTime.now();
                        final startOfWeek = DateTime(
                          now.year,
                          now.month,
                          now.day - (now.weekday - 1),
                        );

                        for (var doc in snapshotPresencas.data!.docs) {
                          final pData = doc.data() as Map<String, dynamic>;
                          final timestamp = pData['horario'] as Timestamp?;
                          if (timestamp != null) {
                            final date = timestamp.toDate();
                            if (!date.isBefore(startOfWeek)) {
                              workoutsDone++;
                              diasTreinados.add(date.weekday);
                            }
                          }
                        }
                      }

                      final diasList = diasTreinados.toList()..sort();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WeeklyGoalSection(
                            streak: streak,
                            workoutsDone: workoutsDone,
                            weeklyGoal: 3,
                          ),
                          const SizedBox(height: 24),

                          // Banner: some quando QR validado OU chekin já feito
                          if (!validouOuFezCheckinHoje)
                            _buildValidationBanner(context),

                          DailyWorkoutCard(
                            onTap: () => _onIniciarTreino(
                              context,
                              validouOuFezCheckinHoje,
                            ),
                          ),
                          const SizedBox(height: 24),

                          WeeklyProgressBar(diasTreinados: diasList),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const RecentActivitiesList(),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Lógica de navegação ───────────────────────────────────────────────────

  /// Se validou QR hoje → vai para treinos.
  /// Se não → abre modal de validação.
  /// Usa [validouHoje] derivado do StreamBuilder — sem nova leitura do Firestore.
  void _onIniciarTreino(BuildContext context, bool validouHoje) {
    if (validouHoje) {
      Navigator.pushNamed(context, '/workouts');
    } else {
      _showValidacaoModal(context);
    }
  }

  void _showValidacaoModal(BuildContext context) {
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
              Navigator.pushNamed(context, '/workouts');
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

  Widget _buildValidationBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Valide o QR da academia para ganhar pontos hoje.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/checkin'),
            child: Text(
              'Validar',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acesso Rápido', style: AppTypography.h3),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              context,
              icon: Icons.history,
              label: 'Histórico',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.person_outline,
              label: 'Personais',
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(context, '/personals'),
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.show_chart,
              label: 'Progresso',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/progress'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
