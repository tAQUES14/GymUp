import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';
import 'reward_details_page.dart';

// Regra: 1 ponto = R$0,10 · resgate exige custo_pontos completos
const double _kPontoValor = 0.10;

String _fmtReais(double v) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

// ── Configuração visual por tipo de recompensa ─────────────────────────────
class _RewardStyle {
  final IconData icon;
  final List<Color> gradient;
  const _RewardStyle(this.icon, this.gradient);
}

_RewardStyle _styleFor(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('camiseta') || t.contains('roupa')) {
    return const _RewardStyle(
      Icons.checkroom_rounded,
      [Color(0xFF9B8FFF), Color(0xFF6C63FF)],
    );
  }
  if (t.contains('squeeze') || t.contains('garrafa')) {
    return const _RewardStyle(
      Icons.water_drop_rounded,
      [Color(0xFF4DD0E1), Color(0xFF0097A7)],
    );
  }
  if (t.contains('mensalidade') || t.contains('desconto')) {
    return const _RewardStyle(
      Icons.percent_rounded,
      [Color(0xFFFFB74D), Color(0xFFF57C00)],
    );
  }
  if (t.contains('personal') || t.contains('aula')) {
    return const _RewardStyle(
      Icons.fitness_center_rounded,
      [Color(0xFFEF9A9A), Color(0xFFE53935)],
    );
  }
  return const _RewardStyle(
    Icons.card_giftcard_rounded,
    [Color(0xFF9B8FFF), Color(0xFF6C63FF)],
  );
}

// ── Mock data ──────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _mockRewards = [
  {
    'id': 'mock_1',
    'titulo': 'Camiseta GymUp',
    'custo_pontos': 500,
    'preco_original': 50.0,
    'descricao': 'Camiseta dry-fit oficial. Disponível em P, M, G e GG.',
    'imagem_url': '',
  },
  {
    'id': 'mock_2',
    'titulo': 'Squeeze 500 ml',
    'custo_pontos': 300,
    'preco_original': 30.0,
    'descricao': 'Garrafa resistente e estilosa para seus treinos.',
    'imagem_url': '',
  },
  {
    'id': 'mock_3',
    'titulo': '10% na Mensalidade',
    'custo_pontos': 1000,
    'preco_original': 100.0,
    'descricao': '10% de desconto na próxima mensalidade.',
    'imagem_url': '',
  },
  {
    'id': 'mock_4',
    'titulo': 'Aula com Personal (1h)',
    'custo_pontos': 2000,
    'preco_original': 200.0,
    'descricao': 'Aula exclusiva com personal trainer.',
    'imagem_url': '',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// STORE PAGE
// ─────────────────────────────────────────────────────────────────────────────

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Loja'),
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getAlunoStream(),
        builder: (context, userSnap) {
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final int userPoints =
              (userData['pontos'] as num?)?.toInt() ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getRecompensasStream(),
            builder: (context, rewardSnap) {
              if (rewardSnap.connectionState == ConnectionState.waiting &&
                  userSnap.connectionState == ConnectionState.waiting) {
                return const GymUpLoading();
              }

              if (rewardSnap.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar. Verifique sua conexão.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final docs = rewardSnap.data?.docs ?? [];
              final List<Map<String, dynamic>> rewards = docs.isNotEmpty
                  ? docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      data['id'] = d.id;
                      return data;
                    }).toList()
                  : _mockRewards;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _BalanceStrip(userPoints: userPoints),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.80,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _RewardCard(
                          data: rewards[i],
                          userPoints: userPoints,
                        ),
                        childCount: rewards.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALANCE STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceStrip extends StatelessWidget {
  final int userPoints;
  const _BalanceStrip({required this.userPoints});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meu saldo',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '$userPoints pts',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '≈ ${_fmtReais(userPoints * _kPontoValor)}',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARD CARD (grid)
// ─────────────────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int userPoints;

  const _RewardCard({required this.data, required this.userPoints});

  @override
  Widget build(BuildContext context) {
    final String id = data['id'] ?? '';
    final String titulo = data['titulo'] ?? 'Recompensa';
    final int custoPontos = (data['custo_pontos'] as num?)?.toInt() ?? 0;
    final bool unlocked = userPoints >= custoPontos;
    final int faltam = unlocked ? 0 : custoPontos - userPoints;
    final cfg = _styleFor(titulo);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RewardDetailsPage(rewardId: id, data: data),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient top ──────────────────────────────────────
              Expanded(
                flex: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cfg.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Locked overlay
                    if (!unlocked)
                      Container(
                        color: Colors.black.withValues(alpha: 0.10),
                      ),
                    Center(
                      child: Icon(
                        cfg.icon,
                        size: 44,
                        color: Colors.white
                            .withValues(alpha: unlocked ? 1.0 : 0.65),
                      ),
                    ),
                    if (!unlocked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white70,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── White bottom ──────────────────────────────────────
              Expanded(
                flex: 44,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titulo,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _PointsBadge(
                        custoPontos: custoPontos,
                        unlocked: unlocked,
                        faltam: faltam,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POINTS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _PointsBadge extends StatelessWidget {
  final int custoPontos;
  final bool unlocked;
  final int faltam;

  const _PointsBadge({
    required this.custoPontos,
    required this.unlocked,
    required this.faltam,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.accent : AppColors.primary;
    final icon = unlocked
        ? Icons.check_circle_rounded
        : Icons.stars_rounded;
    final label = unlocked ? '$custoPontos pts' : '+$faltam pts';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
