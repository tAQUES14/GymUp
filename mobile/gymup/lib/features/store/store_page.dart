import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import 'reward_api_service.dart';
import 'reward_model.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// STORE PAGE
// ─────────────────────────────────────────────────────────────────────────────

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Reward>? _rewards;
  int _userPoints = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        RewardApiService().getRewards(),
        AuthApiService().getMe(),
      ]);

      if (mounted) {
        setState(() {
          _rewards = results[0] as List<Reward>;
          final user = results[1] as Map<String, dynamic>;
          _userPoints = (user['points_balance'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = 'Erro ao carregar. Verifique sua conexão.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Loja'),
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GymUpLoading();
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final rewards = _rewards ?? [];

    if (rewards.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma recompensa disponível no momento.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BalanceStrip(userPoints: _userPoints),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.80,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _RewardCard(
                reward: rewards[i],
                userPoints: _userPoints,
              ),
              childCount: rewards.length,
            ),
          ),
        ),
      ],
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
  final Reward reward;
  final int userPoints;

  const _RewardCard({required this.reward, required this.userPoints});

  @override
  Widget build(BuildContext context) {
    final String titulo = reward.name;
    final int custoPontos = reward.pointsCost;
    final bool unlocked = userPoints >= custoPontos;
    final int faltam = unlocked ? 0 : custoPontos - userPoints;
    final cfg = _styleFor(titulo);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RewardDetailsPage(
            reward: reward,
            userPoints: userPoints,
          ),
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
