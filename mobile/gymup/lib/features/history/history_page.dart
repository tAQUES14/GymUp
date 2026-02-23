import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Histórico de Pontos'),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPresencasStream(),
        builder: (context, snapshotPresencas) {
          if (snapshotPresencas.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getResgatesStream(),
            builder: (context, snapshotResgates) {
              if (snapshotResgates.connectionState == ConnectionState.waiting) {
                return const GymUpLoading();
              }

              final presencas = snapshotPresencas.data?.docs ?? [];
              final resgates = snapshotResgates.data?.docs ?? [];

              final List<Map<String, dynamic>> history = [];

              for (var doc in presencas) {
                final data = doc.data() as Map<String, dynamic>;
                history.add({
                  'type': 'checkin',
                  'title': 'Check-in Realizado',
                  'points': data['pontosGanhos'] ?? 10,
                  'date':
                      (data['horario'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  'isPositive': true,
                });
              }

              for (var doc in resgates) {
                final data = doc.data() as Map<String, dynamic>;
                history.add({
                  'type': 'resgate',
                  'title': 'Resgate de Recompensa',
                  'points': data['custo'] ?? 0,
                  'date':
                      (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'isPositive': false,
                });
              }

              // Sort by date descending
              history.sort(
                (a, b) =>
                    (b['date'] as DateTime).compareTo(a['date'] as DateTime),
              );

              if (history.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum histórico encontrado.',
                    style: AppTypography.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final date = item['date'] as DateTime;
                  final formattedDate = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(date);
                  final isPositive = item['isPositive'] as bool;
                  final points = item['points'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GymUpCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.check_circle
                                  : Icons.shopping_bag,
                              color: isPositive
                                  ? AppColors.accent
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isPositive ? '+$points' : '-$points',
                            style: AppTypography.h3.copyWith(
                              color: isPositive
                                  ? AppColors.accent
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
