import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGreen    = Color(0xFF10B981);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>>? _history;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService().get('/points/history?per_page=50');

      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode != 200) throw Exception('Erro ao carregar histórico');

      final body = jsonDecode(response.body);
      final List<dynamic> items =
          body is List ? body : (body['data'] as List<dynamic>? ?? []);

      final history = items.map<Map<String, dynamic>>((item) {
        final bool isEarn = (item['type'] as String?) == 'earn';
        return {
          'title': item['description'] as String? ?? 'Movimentação',
          'points': (item['points'] as num?)?.toInt() ?? 0,
          'date': DateTime.parse(item['created_at'] as String),
          'isPositive': isEarn,
        };
      }).toList()
        ..sort((a, b) =>
            (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (!mounted) return;
      setState(() { _history = history; _loading = false; });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Histórico de Pontos',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const GymUpLoading();

    if (_error != null) {
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
                child: Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Erro ao carregar',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kBlue, _kBlueDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Tentar novamente',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final history = _history ?? [];

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, color: _kBlue, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Sem histórico',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Nenhuma movimentação de pontos encontrada.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
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
      color: _kBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        itemCount: history.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryHeader(totalEarned, totalSpent, history.length);
          }
          return _buildTransactionItem(history[index - 1]);
        },
      ),
    );
  }

  // ── Summary hero ─────────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(int earned, int spent, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
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
                child: const Icon(Icons.history_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      )),
                  const Text('Movimentações',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats row
        Row(
          children: [
            Expanded(
              child: _statPill('+$earned pts', 'Ganhos', _kGreen,
                  Icons.arrow_upward_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statPill('-$spent pts', 'Gastos', AppColors.error,
                  Icons.arrow_downward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Movimentações',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _statPill(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction item ──────────────────────────────────────────────────────────

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    final isPositive = item['isPositive'] as bool;
    final points     = item['points'] as int;
    final date       = item['date'] as DateTime;
    final formatted  = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final color      = isPositive ? _kGreen : AppColors.error;
    final icon       = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.shopping_bag_rounded;

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
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 3),
                  Text(formatted,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Text(
              isPositive ? '+$points pts' : '-$points pts',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
