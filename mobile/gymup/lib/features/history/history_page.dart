import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kLine = Color(0x140E1116);
const _kGreen = Color(0xFF12B981);
const _kRed = Color(0xFFEF4444);
const _kAmber = Color(0xFFE5A300);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>>? _history;
  Map<int, String> _redemptionStatus = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final results = await Future.wait([
        api.get('/points/history?per_page=50'),
        api.get('/user/redemptions?per_page=50'),
      ]);

      final historyResp = results[0];
      final redemptResp = results[1];

      if (historyResp.statusCode == 401 || redemptResp.statusCode == 401) {
        throw Exception('401');
      }
      if (historyResp.statusCode != 200) {
        throw Exception('Erro ao carregar histórico');
      }

      final statusMap = <int, String>{};
      if (redemptResp.statusCode == 200) {
        final rb = jsonDecode(redemptResp.body);
        final rList = rb is List ? rb : (rb['data'] as List<dynamic>? ?? []);

        for (final r in rList) {
          final id = (r['id'] as num).toInt();
          final status = r['status'] as String? ?? 'pending';
          statusMap[id] = status;
        }
      }

      final body = jsonDecode(historyResp.body);
      final items = body is List ? body : (body['data'] as List<dynamic>? ?? []);

      final history = items.map<Map<String, dynamic>>((item) {
        final isEarn = (item['type'] as String?) == 'earn';
        final category = item['category'] as String?;
        final referenceId = (item['reference_id'] as num?)?.toInt();

        return {
          'title': item['description'] as String? ?? 'Movimentação',
          'points': (item['points'] as num?)?.toInt() ?? 0,
          'date': DateTime.parse(item['created_at'] as String),
          'isPositive': isEarn,
          'category': category,
          'reference_id': referenceId,
        };
      }).toList()
        ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (!mounted) return;
      setState(() {
        _history = history;
        _redemptionStatus = statusMap;
        _loading = false;
      });
    } catch (e) {
      if (e.toString().contains('401') && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.pop(context)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const GymUpLoading();

    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.error,
        title: 'Erro ao carregar',
        message: _error!,
        actionLabel: 'Tentar novamente',
        onAction: _loadData,
      );
    }

    final history = _history ?? [];

    if (history.isEmpty) {
      return const _StateMessage(
        icon: Icons.history_rounded,
        iconColor: AppColors.blue,
        title: 'Sem movimentações',
        message: 'Nenhuma movimentação de pontos encontrada.',
      );
    }

    final totalEarned = history
        .where((i) => i['isPositive'] == true)
        .fold<int>(0, (sum, i) => sum + (i['points'] as int));
    final totalSpent = history
        .where((i) => i['isPositive'] == false)
        .fold<int>(0, (sum, i) => sum + (i['points'] as int));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.blue,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
        itemCount: history.length + 2,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 18 : 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SummarySection(
              earned: totalEarned,
              spent: totalSpent,
              count: history.length,
            );
          }

          if (index == 1) {
            return Text(
              'Movimentações',
              style: AppTypography.h3.copyWith(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            );
          }

          return _TransactionItem(
            item: history[index - 2],
            redemptionStatus: _redemptionStatus,
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              'Histórico de Pontos',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final int earned;
  final int spent;
  final int count;

  const _SummarySection({
    required this.earned,
    required this.spent,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimaryDark,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.26),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 1 ? 'movimentação registrada' : 'movimentações registradas',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '+${_fmt(earned)} pts',
                label: 'Ganhos',
                color: _kGreen,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '-${_fmt(spent)} pts',
                label: 'Gastos',
                color: _kRed,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: _kSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<int, String> redemptionStatus;

  const _TransactionItem({
    required this.item,
    required this.redemptionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = item['isPositive'] as bool;
    final points = item['points'] as int;
    final date = item['date'] as DateTime;
    final category = item['category'] as String?;
    final referenceId = item['reference_id'] as int?;
    final status = category == 'redemption' && !isPositive && referenceId != null
        ? redemptionStatus[referenceId]
        : null;

    final color = isPositive ? _kGreen : _kRed;
    final icon = isPositive ? Icons.arrow_upward_rounded : Icons.shopping_bag_rounded;
    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(date);

    var title = item['title'] as String;
    if (status == 'approved') {
      title = 'Resgate aprovado';
    } else if (status == 'rejected') {
      title = 'Resgate rejeitado';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    color: _kInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatted,
                      style: AppTypography.caption.copyWith(
                        color: _kSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status != null) _RedemptionStatusChip(status: status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isPositive ? '+${_fmt(points)} pts' : '-${_fmt(points)} pts',
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedemptionStatusChip extends StatelessWidget {
  final String status;

  const _RedemptionStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Aprovado', _kGreen),
      'rejected' => ('Rejeitado', _kRed),
      _ => ('Aguardando', _kAmber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _kInk, size: 21),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                color: _kInk,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: _kMuted,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(int value) => NumberFormat.decimalPattern('pt_BR').format(value);
