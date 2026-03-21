import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'reward_api_service.dart';
import 'reward_model.dart';

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF10B981);
const double _kPontoValor = 0.10;

String _fmtReais(double v) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

class _RS {
  final IconData icon;
  final List<Color> gradient;
  const _RS(this.icon, this.gradient);
}

_RS _styleFor(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('camiseta') || t.contains('roupa')) {
    return const _RS(Icons.checkroom_rounded,
        [Color(0xFF9B8FFF), Color(0xFF6C63FF)]);
  }
  if (t.contains('squeeze') || t.contains('garrafa')) {
    return const _RS(Icons.water_drop_rounded,
        [Color(0xFF4DD0E1), Color(0xFF0097A7)]);
  }
  if (t.contains('mensalidade') || t.contains('desconto')) {
    return const _RS(Icons.percent_rounded,
        [Color(0xFFFFB74D), Color(0xFFF57C00)]);
  }
  if (t.contains('personal') || t.contains('aula')) {
    return const _RS(Icons.fitness_center_rounded,
        [Color(0xFFEF9A9A), Color(0xFFE53935)]);
  }
  return const _RS(Icons.card_giftcard_rounded,
      [Color(0xFF9B8FFF), Color(0xFF6C63FF)]);
}

class RewardDetailsPage extends StatefulWidget {
  final Reward? reward;
  final int userPoints;
  const RewardDetailsPage({super.key, this.reward, this.userPoints = 0});

  @override
  State<RewardDetailsPage> createState() => _RewardDetailsPageState();
}

class _RewardDetailsPageState extends State<RewardDetailsPage> {
  bool _isLoading = false;

  Future<void> _resgatar(int custoPontos) async {
    final reward = widget.reward;
    if (reward == null || widget.userPoints < custoPontos) return;
    setState(() => _isLoading = true);
    try {
      await RewardApiService().redeemReward(reward.id);
      if (mounted) {
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
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    if (reward == null) {
      return const Scaffold(body: Center(child: Text('Não encontrado')));
    }

    final titulo        = reward.name;
    final descricao     = reward.description;
    final custoPontos   = reward.pointsCost;
    final precoOriginal = custoPontos * _kPontoValor;
    final userPoints    = widget.userPoints;
    final temPontos     = userPoints >= custoPontos;
    final faltam        = temPontos ? 0 : custoPontos - userPoints;
    final cfg           = _styleFor(titulo);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: cfg.gradient.first,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titulo,
          style: AppTypography.bodyLarge
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero: imagem real ou gradiente ────────────────────
          SizedBox(
            height: 200,
            width: double.infinity,
            child: reward.imageUrl != null
                ? Image.network(
                    reward.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, st) => _HeroGradient(cfg: cfg),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _HeroGradient(cfg: cfg),
                  )
                : _HeroGradient(cfg: cfg),
          ),

          // ── Content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: AppTypography.h2),
                  if (descricao.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(descricao,
                        style: AppTypography.bodyMedium
                            .copyWith(height: 1.55,
                                color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 28),

                  // ── Price row ──────────────────────────────────
                  _PriceRow(
                      precoOriginal: precoOriginal, custoPontos: custoPontos),
                  const SizedBox(height: 24),

                  // ── Points progress ────────────────────────────
                  _PointsProgress(
                    userPoints: userPoints,
                    custoPontos: custoPontos,
                    temPontos: temPontos,
                    faltam: faltam,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Fixed CTA ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: temPontos
                ? GestureDetector(
                    onTap: _isLoading ? null : () => _resgatar(custoPontos),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isLoading ? 0.7 : 1.0,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cfg.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  cfg.gradient.first.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Resgatar  ·  $custoPontos pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Faltam $faltam pontos',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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

// ── Hero Gradient (fallback sem imagem) ───────────────────────────────────────

class _HeroGradient extends StatelessWidget {
  final _RS cfg;
  const _HeroGradient({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cfg.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(cfg.icon, size: 76, color: Colors.white)),
    );
  }
}

// ── Price Row ─────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final double precoOriginal;
  final int custoPontos;
  const _PriceRow({required this.precoOriginal, required this.custoPontos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preço original',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _fmtReais(precoOriginal),
                  style: AppTypography.bodyLarge.copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textSecondary,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded,
              color: Color(0xFFCBD5E1), size: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$custoPontos pts',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'GRÁTIS',
                  style: AppTypography.h3.copyWith(color: _kGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Points Progress ───────────────────────────────────────────────────────────

class _PointsProgress extends StatelessWidget {
  final int userPoints;
  final int custoPontos;
  final bool temPontos;
  final int faltam;

  const _PointsProgress({
    required this.userPoints,
    required this.custoPontos,
    required this.temPontos,
    required this.faltam,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        custoPontos > 0 ? (userPoints / custoPontos).clamp(0.0, 1.0) : 1.0;
    final barColor = temPontos ? _kGreen : _kBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seu saldo',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
              Text(
                '$userPoints / $custoPontos pts',
                style: AppTypography.caption.copyWith(
                  color: temPontos ? _kGreen : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          if (!temPontos)
            Text(
              'Faltam $faltam pontos para resgatar',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _kGreen, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Você pode resgatar este item!',
                  style: AppTypography.caption.copyWith(
                    color: _kGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Success Dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onOk;
  const _SuccessDialog({required this.onOk});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: _kGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Pedido enviado!',
              style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Solicitação registrada com status PENDENTE.\n'
            'Apresente na recepção — seus pontos só são '
            'debitados após a confirmação.',
            style:
                AppTypography.bodyMedium.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onOk,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kBlue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('OK',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
