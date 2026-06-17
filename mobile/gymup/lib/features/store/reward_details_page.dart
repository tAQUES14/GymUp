import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/gym_feedback.dart';
import '../auth/auth_api_service.dart';
import 'reward_api_service.dart';
import 'reward_model.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kLime = Color(0xFFC8F84A);
const _kGreen = Color(0xFF5BA300);
const _kOrange = Color(0xFFFF7A1A);
const _kPurple = Color(0xFF7A5AE0);

class RewardDetailsPage extends StatefulWidget {
  final Reward? reward;
  final int userPoints;

  const RewardDetailsPage({super.key, this.reward, this.userPoints = 0});

  @override
  State<RewardDetailsPage> createState() => _RewardDetailsPageState();
}

class _RewardDetailsPageState extends State<RewardDetailsPage> {
  bool _isLoading = false;
  late int _userPoints = widget.userPoints;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  Future<void> _loadCurrentBalance() async {
    try {
      final user = await AuthApiService().getMe();
      final points = (user['points_balance'] as num?)?.toInt();
      if (!mounted || points == null) return;
      setState(() => _userPoints = points);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt('profile_points_balance');
      if (!mounted || cached == null) return;
      setState(() => _userPoints = cached);
    }
  }

  Future<void> _resgatar(int custoPontos) async {
    final reward = widget.reward;
    if (reward == null || _userPoints < custoPontos) return;
    setState(() => _isLoading = true);
    try {
      await RewardApiService().redeemReward(reward.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          onOk: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      showGymSnack(context, msg, kind: GymFeedbackKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    if (reward == null) {
      return const Scaffold(body: Center(child: Text('Nao encontrado')));
    }

    final category = _rewardCategory(reward);
    final canRedeem = _userPoints >= reward.pointsCost;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProductHero(
                  reward: reward,
                  category: category,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 118 + bottomInset),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _ProductIntro(reward: reward, category: category),
                      const SizedBox(height: 14),
                      _CostBalanceCard(
                        cost: reward.pointsCost,
                        balance: _userPoints,
                        canRedeem: canRedeem,
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Detalhes'),
                      const SizedBox(height: 10),
                      _DetailsCard(reward: reward),
                      const SizedBox(height: 18),
                      _sectionTitle('Como funciona'),
                      const SizedBox(height: 10),
                      _HowItWorksCard(cost: reward.pointsCost),
                      const SizedBox(height: 18),
                      _StockCard(reward: reward),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomDock(
              cost: reward.pointsCost,
              canRedeem: canRedeem,
              isLoading: _isLoading,
              bottomInset: bottomInset,
              onRedeem: () => _resgatar(reward.pointsCost),
              missing: canRedeem ? 0 : reward.pointsCost - _userPoints,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHero extends StatelessWidget {
  final Reward reward;
  final _RewardCategory category;
  final VoidCallback onBack;

  const _ProductHero({
    required this.reward,
    required this.category,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.29, -0.12),
          end: const Alignment(0.71, 1.12),
          colors: [category.bg, Colors.white, const Color(0xFFF0FFD9)],
        ),
      ),
      child: Stack(
        children: [
          if (reward.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                reward.imageUrl!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _HeroFallback(category: category),
              ),
            )
          else
            Positioned.fill(child: _HeroFallback(category: category)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 90,
            child: _HotBadge(),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _topButton(Icons.arrow_back_ios_new_rounded, onBack),
                  const Spacer(),
                  _topButton(Icons.share_rounded, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductIntro extends StatelessWidget {
  final Reward reward;
  final _RewardCategory category;

  const _ProductIntro({required this.reward, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _CategoryChip(category: category),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: _kOrange),
                  const SizedBox(width: 3),
                  Text('4,8', style: _sg(size: 11, weight: FontWeight.w700, color: _kInk)),
                  Text(' · 86', style: _pjs(size: 11, weight: FontWeight.w700, color: _kSoft)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reward.name,
            style: _pjs(
              size: 26,
              weight: FontWeight.w800,
              color: _kInk,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reward.description.isEmpty
                ? 'Recompensa exclusiva da academia para resgate com seus pontos GymUp.'
                : reward.description,
            style: _pjs(
              size: 13.5,
              weight: FontWeight.w500,
              color: _kMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final _RewardCategory category;

  const _HeroFallback({required this.category});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.29, -0.12),
                end: const Alignment(0.71, 1.12),
                colors: [category.bg, Colors.white, const Color(0xFFF0FFD9)],
              ),
            ),
          ),
        ),
        Positioned(right: -60, top: -60, child: _radial(_kLime, 280, 0.45)),
        Positioned(left: -50, bottom: -50, child: _radial(_kBlue, 240, 0.18)),
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.24),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Icon(category.icon, color: category.accent, size: 76),
          ),
        ),
      ],
    );
  }
}

class _CostBalanceCard extends StatelessWidget {
  final int cost;
  final int balance;
  final bool canRedeem;

  const _CostBalanceCard({
    required this.cost,
    required this.balance,
    required this.canRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteDecoration(20),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _MetricBlock(
                label: 'CUSTO',
                value: _fmtPoints(cost),
                suffix: 'pts',
                valueSize: 28,
                valueColor: _kInk,
              ),
            ),
            Container(width: 1, color: _kInk.withValues(alpha: 0.06)),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricBlock(
                label: 'EM SEU SALDO',
                value: _fmtPoints(balance),
                suffix: 'pts',
                valueSize: 22,
                valueColor: canRedeem ? _kGreen : _kMuted,
                trailing: canRedeem
                    ? Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _kGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final double valueSize;
  final Color valueColor;
  final Widget? trailing;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.suffix,
    required this.valueSize,
    required this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: _eyebrow(size: 10.5, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: _sg(
                        size: valueSize,
                        weight: FontWeight.w700,
                        color: valueColor,
                        height: 1,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(suffix, style: _sg(size: 12, weight: FontWeight.w700, color: _kSoft)),
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Reward reward;

  const _DetailsCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final specs = _specsFor(reward);
    return Container(
      height: 166,
      padding: const EdgeInsets.all(4),
      decoration: _whiteDecoration(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    spec: specs[0],
                    border: Border(
                      right: BorderSide(color: _kInk.withValues(alpha: 0.06)),
                      bottom: BorderSide(color: _kInk.withValues(alpha: 0.06)),
                    ),
                  ),
                ),
                Expanded(
                  child: _DetailTile(
                    spec: specs[1],
                    border: Border(bottom: BorderSide(color: _kInk.withValues(alpha: 0.06))),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    spec: specs[2],
                    border: Border(right: BorderSide(color: _kInk.withValues(alpha: 0.06))),
                  ),
                ),
                Expanded(child: _DetailTile(spec: specs[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final _Spec spec;
  final Border? border;

  const _DetailTile({required this.spec, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(border: border),
      child: Row(
        children: [
          _DetailIcon(spec: spec),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _eyebrow(size: 9.5, letterSpacing: 0.4),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        spec.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sg(size: 14, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
                      ),
                    ),
                    if (spec.suffix != null) ...[
                      const SizedBox(width: 3),
                      Text(spec.suffix!, style: _sg(size: 10.5, weight: FontWeight.w700, color: _kSoft)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailIcon extends StatelessWidget {
  final _Spec spec;

  const _DetailIcon({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(spec.icon, color: spec.accent, size: 17),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final int cost;

  const _HowItWorksCard({required this.cost});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('01', 'Toque em Resgatar', '${_fmtPoints(cost)} pts serao reservados do seu saldo.'),
      ('02', 'Aguarde aprovacao', 'A academia revisa o pedido em ate 48h.'),
      ('03', 'Retire na recepcao', 'Apresente o codigo de resgate no app.'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteDecoration(18),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              number: steps[i].$1,
              title: steps[i].$2,
              subtitle: steps[i].$3,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool isLast;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15, top: isLast ? 0 : 0),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: _kInk.withValues(alpha: 0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFE),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: _sg(size: 13, weight: FontWeight.w700, color: _kBlueDark, letterSpacing: -0.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _pjs(size: 13.5, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final Reward reward;

  const _StockCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final stock = reward.stock;
    final hasStock = stock == null || stock > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteDecoration(18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasStock ? const Color(0xFFEDFBD3) : const Color(0xFFFFEDDC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              hasStock ? Icons.inventory_2_rounded : Icons.inventory_2_outlined,
              color: hasStock ? _kGreen : _kOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock == null ? 'Disponivel para resgate' : '$stock unidades disponiveis',
                  style: _pjs(size: 13.5, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2),
                ),
                const SizedBox(height: 1),
                Text(
                  'Retirada na recepcao da academia',
                  style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: hasStock ? const Color(0xFFEDFBD3) : const Color(0xFFFFEDDC),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              hasStock ? 'EM ESTOQUE' : 'ESGOTADO',
              style: _pjs(
                size: 10,
                weight: FontWeight.w800,
                color: hasStock ? _kGreen : _kOrange,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  final int cost;
  final bool canRedeem;
  final bool isLoading;
  final double bottomInset;
  final int missing;
  final VoidCallback onRedeem;

  const _BottomDock({
    required this.cost,
    required this.canRedeem,
    required this.isLoading,
    required this.bottomInset,
    required this.missing,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 17, 20, 26 + bottomInset),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: Color(0x0F0E1116))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL', style: _eyebrow(size: 10, letterSpacing: 0.4)),
              const SizedBox(height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _fmtPoints(cost),
                    style: _sg(
                      size: 22,
                      weight: FontWeight.w700,
                      color: _kInk,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text('pts', style: _sg(size: 11, weight: FontWeight.w700, color: _kMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: canRedeem && !isLoading ? onRedeem : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isLoading ? 0.70 : 1,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: canRedeem
                        ? const LinearGradient(
                            begin: Alignment(0.20, -1.12),
                            end: Alignment(0.80, 2.12),
                            colors: [_kBlueDark, _kBlue, Color(0xFF4A8CFF)],
                          )
                        : null,
                    color: canRedeem ? null : _kInk.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: canRedeem
                        ? [
                            BoxShadow(
                              color: _kBlue.withValues(alpha: 0.36),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canRedeem ? Icons.card_giftcard_rounded : Icons.lock_rounded,
                                color: canRedeem ? Colors.white : _kSoft,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  canRedeem ? 'Resgatar' : 'Faltam ${_fmtPoints(missing)} pontos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: _pjs(
                                    size: canRedeem ? 15 : 13,
                                    weight: FontWeight.w800,
                                    color: canRedeem ? Colors.white : _kSoft,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onOk;

  const _SuccessDialog({required this.onOk});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBlueDark, _kBlue, Color(0xFF4A8CFF)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _kBlueDark,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pedido enviado!',
                  textAlign: TextAlign.center,
                  style: _pjs(
                    size: 21,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solicitacao registrada com sucesso.',
                  textAlign: TextAlign.center,
                  style: _pjs(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            child: Column(
              children: [
                Text(
                  'Apresente na recepcao quando for aprovado.',
                  textAlign: TextAlign.center,
                  style: _pjs(
                    size: 13,
                    weight: FontWeight.w500,
                    color: _kMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onOk,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kBlueDark, _kBlue]),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'OK',
                        style: _pjs(
                          size: 15,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final _RewardCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: category.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '${category.label.toUpperCase()} · EDICAO LIMITADA',
        style: _pjs(size: 10, weight: FontWeight.w800, color: category.accent, letterSpacing: 0.5),
      ),
    );
  }
}

class _HotBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: _kOrange,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            'MAIS RESGATADO',
            style: _pjs(size: 10, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _RewardCategory {
  final String label;
  final Color bg;
  final Color accent;
  final IconData icon;

  const _RewardCategory({
    required this.label,
    required this.bg,
    required this.accent,
    required this.icon,
  });
}

class _Spec {
  final String label;
  final String value;
  final String? suffix;
  final Color bg;
  final Color accent;
  final IconData icon;

  const _Spec({
    required this.label,
    required this.value,
    this.suffix,
    required this.bg,
    required this.accent,
    required this.icon,
  });
}

_RewardCategory _rewardCategory(Reward reward) {
  final text = '${reward.category ?? ''} ${reward.name} ${reward.description}'.toLowerCase();
  if (text.contains('desconto') || text.contains('mensalidade') || text.contains('cupom')) {
    return const _RewardCategory(
      label: 'Desconto',
      bg: Color(0xFFFFEDDC),
      accent: Color(0xFFB85A00),
      icon: Icons.percent_rounded,
    );
  }
  if (text.contains('benef') ||
      text.contains('spa') ||
      text.contains('pass') ||
      text.contains('avaliacao') ||
      text.contains('aula')) {
    return const _RewardCategory(
      label: 'Beneficio',
      bg: Color(0xFFEFE9FD),
      accent: _kPurple,
      icon: Icons.spa_rounded,
    );
  }
  return const _RewardCategory(
    label: 'Produto',
    bg: Color(0xFFE7EEFE),
    accent: _kBlueDark,
    icon: Icons.shopping_bag_rounded,
  );
}

List<_Spec> _specsFor(Reward reward) {
  final text = '${reward.name} ${reward.description}'.toLowerCase();
  if (text.contains('desconto') || text.contains('mensalidade') || text.contains('cupom')) {
    return const [
      _Spec(label: 'TIPO', value: 'Plano', suffix: 'anual', bg: Color(0xFFFFEDDC), accent: Color(0xFFB85A00), icon: Icons.percent_rounded),
      _Spec(label: 'APLICACAO', value: 'Mensalidade', bg: Color(0xFFE7EEFE), accent: _kBlue, icon: Icons.receipt_long_rounded),
      _Spec(label: 'VALIDADE', value: '30', suffix: 'dias', bg: Color(0xFFEDFBD3), accent: _kGreen, icon: Icons.event_available_rounded),
      _Spec(label: 'USO', value: '1', suffix: 'vez', bg: Color(0xFFEFE9FD), accent: _kPurple, icon: Icons.verified_user_outlined),
    ];
  }
  if (text.contains('benef') ||
      text.contains('spa') ||
      text.contains('pass') ||
      text.contains('avaliacao') ||
      text.contains('aula')) {
    return const [
      _Spec(label: 'TIPO', value: 'Servico', bg: Color(0xFFEFE9FD), accent: _kPurple, icon: Icons.spa_rounded),
      _Spec(label: 'DURACAO', value: '1', suffix: 'uso', bg: Color(0xFFE7EEFE), accent: _kBlue, icon: Icons.timer_outlined),
      _Spec(label: 'VALIDADE', value: '30', suffix: 'dias', bg: Color(0xFFEDFBD3), accent: _kGreen, icon: Icons.event_available_rounded),
      _Spec(label: 'RETIRADA', value: 'Recepcao', bg: Color(0xFFFFEDDC), accent: _kOrange, icon: Icons.storefront_rounded),
    ];
  }
  if (text.contains('camiseta') || text.contains('dry')) {
    return const [
      _Spec(label: 'TAMANHO', value: 'P ao GG', bg: Color(0xFFE7EEFE), accent: _kBlue, icon: Icons.straighten_rounded),
      _Spec(label: 'MATERIAL', value: 'Dry', suffix: 'fit', bg: Color(0xFFEDFBD3), accent: _kGreen, icon: Icons.checkroom_rounded),
      _Spec(label: 'PESO', value: '120', suffix: 'g', bg: Color(0xFFFFEDDC), accent: _kOrange, icon: Icons.monitor_weight_outlined),
      _Spec(label: 'GARANTIA', value: '30', suffix: 'dias', bg: Color(0xFFEFE9FD), accent: _kPurple, icon: Icons.verified_user_outlined),
    ];
  }
  return const [
    _Spec(label: 'TAMANHO', value: '600', suffix: 'ml', bg: Color(0xFFE7EEFE), accent: _kBlue, icon: Icons.water_drop_outlined),
    _Spec(label: 'MATERIAL', value: 'BPA', suffix: 'free', bg: Color(0xFFEDFBD3), accent: _kGreen, icon: Icons.eco_outlined),
    _Spec(label: 'PESO', value: '180', suffix: 'g', bg: Color(0xFFFFEDDC), accent: _kOrange, icon: Icons.monitor_weight_outlined),
    _Spec(label: 'GARANTIA', value: '6', suffix: 'meses', bg: Color(0xFFEFE9FD), accent: _kPurple, icon: Icons.verified_user_outlined),
  ];
}

Widget _sectionTitle(String text) {
  return Text(
    text,
    style: _pjs(size: 14, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2),
  );
}

Widget _topButton(IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: _kInk, size: 18),
    ),
  );
}

Widget _radial(Color color, double size, double alpha) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

BoxDecoration _whiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _fmtPoints(int points) {
  return NumberFormat.decimalPattern('pt_BR').format(points);
}

TextStyle _eyebrow({required double size, required double letterSpacing}) {
  return _pjs(size: size, weight: FontWeight.w800, color: _kSoft, letterSpacing: letterSpacing);
}

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _sg({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
