import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _api = ApiService();

  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _summary;
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
      final results = await Future.wait([
        _api.get('/dashboard'),
        _api.get('/me/progress-summary'),
      ]);

      final dashRes = results[0];
      final summaryRes = results[1];

      if (dashRes.statusCode == 401 || summaryRes.statusCode == 401) {
        throw Exception('401');
      }

      if (dashRes.statusCode != 200) {
        throw Exception('Erro ao carregar dashboard');
      }

      final dashboard = jsonDecode(dashRes.body) as Map<String, dynamic>;
      final summary = summaryRes.statusCode == 200
          ? jsonDecode(summaryRes.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
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
      appBar: const GymUpAppBar(title: 'Meu Progresso'),
      backgroundColor: AppColors.background,
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
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboard ?? {};
    final summary = _summary ?? {};

    final int totalPresencas = (data['total_checkins'] as num?)?.toInt() ?? 0;
    final int totalTreinos = (data['total_workouts'] as num?)?.toInt() ?? 0;

    final List<int> weeklyPoints =
        (data['weekly_points'] as List<dynamic>? ?? [0, 0, 0, 0])
            .map((e) => (e as num).toInt())
            .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCards(totalPresencas, totalTreinos),
            const SizedBox(height: 32),
            Text('Pontos nas últimas 4 semanas', style: AppTypography.h3),
            const SizedBox(height: 16),
            _buildChart(weeklyPoints),
            const SizedBox(height: 32),

            // Evolução 30 dias
            _buildEvolutionCard(summary),
            const SizedBox(height: 16),

            // PR mais recente
            _buildLatestPRCard(summary),
            const SizedBox(height: 16),

            // Maior evolução
            _buildBestExerciseCard(summary),
            const SizedBox(height: 32),

            _buildAchievementCard(totalTreinos),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Summary Cards (existentes)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryCards(int presencas, int treinos) {
    return Row(
      children: [
        Expanded(
          child: GymUpCard(
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  '$presencas',
                  style: AppTypography.h1.copyWith(color: Colors.white),
                ),
                Text(
                  'Presenças',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GymUpCard(
            child: Column(
              children: [
                Text(
                  '$treinos',
                  style: AppTypography.h1.copyWith(color: AppColors.primary),
                ),
                Text('Treinos', style: AppTypography.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Chart (existente)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildChart(List<int> data) {
    final int max =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);

    return GymUpCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final int value = data[index];
            final double heightFactor =
                max == 0 ? 0.0 : (value / max).toDouble();

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heightFactor),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, val, child) {
                    return Container(
                      width: 30,
                      height: 150 * val,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Sem ${index + 1}', style: AppTypography.caption),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Evolução 30 dias
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEvolutionCard(Map<String, dynamic> summary) {
    final deltaPct = (summary['overall_delta_pct'] as num?)?.toDouble();
    final deltaAbs = (summary['overall_delta_abs'] as num?)?.toDouble();

    if (deltaPct == null || deltaAbs == null) {
      return GymUpCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.textSecondary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Evolução 30 dias: sem dados suficientes ainda.',
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final isPositive = deltaPct >= 0;
    final color = isPositive ? AppColors.accent : AppColors.error;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final sign = isPositive ? '+' : '';

    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evolução 30 dias', style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '$sign${deltaPct.toStringAsFixed(1)}%  ($sign${deltaAbs.toStringAsFixed(1)} kg e1RM)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PR Mais Recente
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildLatestPRCard(Map<String, dynamic> summary) {
    final pr = summary['latest_pr'] as Map<String, dynamic>?;

    if (pr == null) {
      return const SizedBox.shrink();
    }

    final name = pr['name'] as String? ?? '';
    final weight = (pr['weight'] as num?)?.toDouble() ?? 0;
    final reps = (pr['reps'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PR Mais Recente',
                  style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$name — ${weight.toStringAsFixed(1)} kg x $reps reps',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Maior Evolução (exercício)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBestExerciseCard(Map<String, dynamic> summary) {
    final best = summary['best_exercise'] as Map<String, dynamic>?;

    if (best == null) {
      return const SizedBox.shrink();
    }

    final name = best['name'] as String? ?? '';
    final deltaPct = (best['delta_pct'] as num?)?.toDouble() ?? 0;
    final sign = deltaPct >= 0 ? '+' : '';

    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maior Evolução', style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '$name  $sign${deltaPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Achievement (existente)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAchievementCard(int totalTreinos) {
    final double progresso = ((totalTreinos % 20) / 20).toDouble();

    return GymUpCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Text('Próxima Conquista', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(
            'Complete 20 treinos para ganhar o badge "Dedicado"!',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.warning),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('${totalTreinos % 20} / 20', style: AppTypography.caption),
        ],
      ),
    );
  }
}
