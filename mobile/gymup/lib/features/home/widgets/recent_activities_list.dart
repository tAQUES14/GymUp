import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../services/firestore_service.dart';

/// Retorna uma string de tempo relativo baseada no [timestamp] fornecido.
///
/// - Diferença de 0 dias → "Hoje"
/// - Diferença de 1 dia  → "Ontem"
/// - Demais              → "Há X dias"
String _formatarTempoRelativo(Timestamp timestamp) {
  final agora = DateTime.now();
  final dataEvento = timestamp.toDate();

  // Compara apenas a data (sem hora) para calcular a diferença correta
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final diaEvento = DateTime(dataEvento.year, dataEvento.month, dataEvento.day);

  final diferenca = hoje.difference(diaEvento).inDays;

  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';
  return 'Há $diferenca dias';
}

/// Exibe as últimas atividades de check-in do aluno com dados reais
/// da coleção "presencas" via [FirestoreService.getPresencasStream()].
///
/// Limita a 5 registros e ordena por horário decrescente (já garantido
/// pelo stream). Não usa dados mock.
class RecentActivitiesList extends StatelessWidget {
  const RecentActivitiesList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimas atividades', style: AppTypography.h3),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getPresencasStream(),
          builder: (context, snapshot) {
            // ── Estado de carregamento ─────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            // ── Erro de leitura ────────────────────────────────────────
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Não foi possível carregar as atividades.',
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              );
            }

            // ── Sem dados ──────────────────────────────────────────────
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhuma atividade ainda.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              );
            }

            // ── Lista — limita aos últimos 5 registros ─────────────────
            final itens = docs.take(5).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final data = itens[index].data() as Map<String, dynamic>;

                // Campos do documento de presença
                final horario = data['horario'] as Timestamp?;
                final pontosGanhos =
                    (data['pontosGanhos'] as num?)?.toInt() ?? 0;

                final tempoRelativo = horario != null
                    ? _formatarTempoRelativo(horario)
                    : '–';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Ícone de sucesso
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Título e subtítulo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in realizado',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(tempoRelativo, style: AppTypography.caption),
                          ],
                        ),
                      ),

                      // Pontos ganhos
                      Text(
                        '+$pontosGanhos pts',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
