import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import 'redemption_model.dart';
import 'reward_api_service.dart';
import 'reward_model.dart';
import 'reward_details_page.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGreen    = Color(0xFF10B981);
const _kAmber    = Color(0xFFF59E0B);
const _kRed      = Color(0xFFEF4444);
const double _kPontoValor = 0.10;

String _fmtReais(double v) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

class _RewardStyle {
  final IconData icon;
  final List<Color> gradient;
  const _RewardStyle(this.icon, this.gradient);
}

_RewardStyle _styleFor(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('camiseta') || t.contains('roupa')) {
    return const _RewardStyle(Icons.checkroom_rounded,
        [Color(0xFF60A5FA), Color(0xFF2563EB)]);
  }
  if (t.contains('squeeze') || t.contains('garrafa')) {
    return const _RewardStyle(Icons.water_drop_rounded,
        [Color(0xFF4DD0E1), Color(0xFF0097A7)]);
  }
  if (t.contains('mensalidade') || t.contains('desconto')) {
    return const _RewardStyle(Icons.percent_rounded,
        [Color(0xFFFFB74D), Color(0xFFF57C00)]);
  }
  if (t.contains('personal') || t.contains('aula')) {
    return const _RewardStyle(Icons.fitness_center_rounded,
        [Color(0xFFEF9A9A), Color(0xFFE53935)]);
  }
  return const _RewardStyle(Icons.card_giftcard_rounded,
      [Color(0xFF60A5FA), Color(0xFF2563EB)]);
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Reward>?      _rewards;
  List<Redemption>?  _redemptions;
  int                _userPoints = 0;
  bool               _isLoading  = true;
  String?            _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        RewardApiService().getRewards(),
        AuthApiService().getMe(),
        RewardApiService().getMyRedemptions(),
      ]);
      if (!mounted) return;
      setState(() {
        _rewards      = results[0] as List<Reward>;
        final user    = results[1] as Map<String, dynamic>;
        _userPoints   = (user['points_balance'] as num?)?.toInt() ?? 0;
        _redemptions  = results[2] as List<Redemption>;
        _isLoading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: _kBlue,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: Text(
            'Loja',
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(text: 'Loja'),
              Tab(text: 'Meus Resgates'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRewardsTab(),
            _buildRedemptionsTab(),
          ],
        ),
      ),
    );
  }

  // ── Aba Loja ─────────────────────────────────────────────────────────────────

  Widget _buildRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_isLoading)
            const SliverFillRemaining(child: GymUpLoading())
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if ((_rewards ?? []).isEmpty)
            SliverFillRemaining(child: _buildRewardsEmpty())
          else ...[
            SliverToBoxAdapter(
                child: _BalanceHero(userPoints: _userPoints)),
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
                    reward: (_rewards ?? [])[i],
                    userPoints: _userPoints,
                    onReturn: _loadData,
                  ),
                  childCount: (_rewards ?? []).length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Aba Meus Resgates ─────────────────────────────────────────────────────────

  Widget _buildRedemptionsTab() {
    if (_isLoading) return const GymUpLoading();
    if (_error != null)  return _buildError();

    final all = _redemptions ?? [];

    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded,
                    size: 32, color: _kBlue.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 16),
              Text('Sem resgates',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Você ainda não resgatou nenhuma recompensa.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // Pendentes primeiro, depois por data decrescente
    final sorted = [...all]
      ..sort((a, b) {
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (a.status != 'pending' && b.status == 'pending') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: sorted.length,
        itemBuilder: (context, i) => _buildRedemptionItem(sorted[i]),
      ),
    );
  }

  Widget _buildRedemptionItem(Redemption r) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: _kBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.rewardName ?? 'Recompensa',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(fmt,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(width: 8),
                      _StatusChip(status: r.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '-${r.pointsSpent} pts',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared error / empty states ───────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Erro ao carregar',
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Tentar novamente',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard_rounded,
                size: 32, color: _kBlue.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('Nenhuma recompensa disponível',
              style: AppTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Volte mais tarde!',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Aprovado ✓', _kGreen),
      'rejected' => ('Rejeitado ✗', _kRed),
      _          => ('Aguardando',  _kAmber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Balance Hero ──────────────────────────────────────────────────────────────

class _BalanceHero extends StatelessWidget {
  final int userPoints;
  const _BalanceHero({required this.userPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.stars_rounded,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meu saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '$userPoints pontos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Equivale a',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                _fmtReais(userPoints * _kPontoValor),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reward Card ───────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int userPoints;
  final VoidCallback? onReturn;
  const _RewardCard(
      {required this.reward, required this.userPoints, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final titulo      = reward.name;
    final custoPontos = reward.pointsCost;
    final unlocked    = userPoints >= custoPontos;
    final faltam      = unlocked ? 0 : custoPontos - userPoints;
    final cfg         = _styleFor(titulo);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RewardDetailsPage(reward: reward, userPoints: userPoints),
        ),
      ).then((_) => onReturn?.call()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
              Expanded(
                flex: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (reward.imageUrl != null)
                      Image.network(
                        reward.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, st) => _GradientBox(
                          gradient: cfg.gradient,
                          icon: cfg.icon,
                          unlocked: unlocked,
                        ),
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : _GradientBox(
                                    gradient: cfg.gradient,
                                    icon: cfg.icon,
                                    unlocked: unlocked,
                                  ),
                      )
                    else
                      _GradientBox(
                        gradient: cfg.gradient,
                        icon: cfg.icon,
                        unlocked: unlocked,
                      ),
                    if (!unlocked)
                      Container(
                          color: Colors.black.withValues(alpha: 0.30)),
                    if (!unlocked)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.white70, size: 11),
                        ),
                      ),
                    if (unlocked)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 11),
                        ),
                      ),
                  ],
                ),
              ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
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

// ── Gradient Box ──────────────────────────────────────────────────────────────

class _GradientBox extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final bool unlocked;
  const _GradientBox({
    required this.gradient,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon,
            size: 44,
            color: Colors.white.withValues(alpha: unlocked ? 1.0 : 0.60)),
      ),
    );
  }
}

// ── Points Badge ──────────────────────────────────────────────────────────────

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
    if (unlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 10, color: _kGreen),
            const SizedBox(width: 4),
            Text(
              '$custoPontos pts',
              style: const TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded,
              size: 10, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            '$custoPontos pts',
            style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 11),
          ),
        ],
      ),
    );
  }
}
