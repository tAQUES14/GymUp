import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_button.dart';
import '../services/firestore_service.dart';

// Regra: 1 ponto = R$0,10 · pontos debitados só após confirmação do admin
const double _kPontoValor = 0.10;

String _fmtReais(double v) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

// Visual config (igual ao store_page — duplicado para evitar acoplamento)
class _RS {
  final IconData icon;
  final List<Color> gradient;
  const _RS(this.icon, this.gradient);
}

_RS _styleFor(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('camiseta') || t.contains('roupa')) {
    return const _RS(Icons.checkroom_rounded, [Color(0xFF9B8FFF), Color(0xFF6C63FF)]);
  }
  if (t.contains('squeeze') || t.contains('garrafa')) {
    return const _RS(Icons.water_drop_rounded, [Color(0xFF4DD0E1), Color(0xFF0097A7)]);
  }
  if (t.contains('mensalidade') || t.contains('desconto')) {
    return const _RS(Icons.percent_rounded, [Color(0xFFFFB74D), Color(0xFFF57C00)]);
  }
  if (t.contains('personal') || t.contains('aula')) {
    return const _RS(Icons.fitness_center_rounded, [Color(0xFFEF9A9A), Color(0xFFE53935)]);
  }
  return const _RS(Icons.card_giftcard_rounded, [Color(0xFF9B8FFF), Color(0xFF6C63FF)]);
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class RewardDetailsPage extends StatefulWidget {
  final String? rewardId;
  final Map<String, dynamic>? data;

  const RewardDetailsPage({super.key, this.rewardId, this.data});

  @override
  State<RewardDetailsPage> createState() => _RewardDetailsPageState();
}

class _RewardDetailsPageState extends State<RewardDetailsPage> {
  bool _isLoading = false;

  Future<void> _resgatar(int userPoints, int custoPontos) async {
    if (widget.rewardId == null || userPoints < custoPontos) return;

    setState(() => _isLoading = true);
    try {
      await context.read<FirestoreService>().criarSolicitacaoResgate(
            recompensaId: widget.rewardId!,
            custoPontos: custoPontos,
            titulo: widget.data?['titulo'] as String? ?? 'Recompensa',
          );

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(
            onOk: () {
              Navigator.pop(context); // fecha dialog
              Navigator.pop(context); // volta para loja
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Scaffold(body: Center(child: Text('Não encontrado')));
    }

    final String titulo = widget.data!['titulo'] ?? 'Recompensa';
    final String descricao = widget.data!['descricao'] ?? '';
    final int custoPontos =
        (widget.data!['custo_pontos'] as num?)?.toInt() ?? 0;
    final double precoOriginal =
        (widget.data!['preco_original'] as num?)?.toDouble() ??
            custoPontos * _kPontoValor;
    final double precoFinal =
        (precoOriginal - custoPontos * _kPontoValor).clamp(0.0, double.infinity);

    final cfg = _styleFor(titulo);

    return Scaffold(
      // AppBar com cor que casa com o gradiente do hero
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
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: context.read<FirestoreService>().getAlunoStream(),
        builder: (context, userSnap) {
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final int userPoints =
              (userData['pontos'] as num?)?.toInt() ?? 0;
          final bool temPontos = userPoints >= custoPontos;
          final int faltam = temPontos ? 0 : custoPontos - userPoints;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero (continua o gradiente do AppBar) ────────────
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cfg.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(cfg.icon, size: 76, color: Colors.white),
                ),
              ),

              // ── Conteúdo rolável ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: AppTypography.h2),
                      if (descricao.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          descricao,
                          style: AppTypography.bodyMedium
                              .copyWith(height: 1.55),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // ── Resumo de preço ──────────────────────────
                      _PriceRow(
                        precoOriginal: precoOriginal,
                        precoFinal: precoFinal,
                        custoPontos: custoPontos,
                      ),
                      const SizedBox(height: 24),

                      // ── Progresso de pontos ──────────────────────
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

              // ── CTA ──────────────────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: temPontos
                    ? GymUpButton(
                        label: 'Resgatar  ·  $custoPontos pts',
                        icon: Icons.card_giftcard_outlined,
                        isLoading: _isLoading,
                        onPressed: () => _resgatar(userPoints, custoPontos),
                      )
                    : GymUpButton(
                        label: 'Faltam $faltam pontos',
                        onPressed: null,
                        color: Colors.grey[200],
                        textColor: AppColors.textSecondary,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICE ROW: De ~~R$50~~ → GRÁTIS
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final double precoOriginal;
  final double precoFinal;
  final int custoPontos;

  const _PriceRow({
    required this.precoOriginal,
    required this.precoFinal,
    required this.custoPontos,
  });

  @override
  Widget build(BuildContext context) {
    final finalLabel = precoFinal <= 0 ? 'GRÁTIS' : _fmtReais(precoFinal);

    return Row(
      children: [
        // Preço original (riscado)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preço original',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
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
            color: AppColors.textSecondary, size: 18),
        // Preço final
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$custoPontos pts',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                finalLabel,
                style: AppTypography.h3.copyWith(
                  color:
                      precoFinal <= 0 ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PONTOS PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

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
    final barColor = temPontos ? AppColors.accent : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seu saldo',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '$userPoints / $custoPontos pts',
              style: AppTypography.caption.copyWith(
                color: temPontos ? AppColors.accent : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        if (!temPontos) ...[
          const SizedBox(height: 8),
          Text(
            'Faltam $faltam pontos para resgatar',
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 14),
              const SizedBox(width: 6),
              Text(
                'Você pode resgatar este item!',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onOk;
  const _SuccessDialog({required this.onOk});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.accent, size: 60),
          const SizedBox(height: 16),
          Text(
            'Pedido enviado!',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Solicitação registrada com status PENDENTE.\n'
            'Apresente na recepção — seus pontos só são '
            'debitados após a confirmação.',
            style: AppTypography.bodyMedium.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onOk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('OK', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }
}
