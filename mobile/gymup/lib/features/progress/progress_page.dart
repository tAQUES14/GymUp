import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../goals/goal_api_service.dart';
import '../goals/goal_summary_page.dart';
import '../goals/create_goal_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _api = ApiService();

  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _summary;
  GoalData?             _goalData;
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
      final results = await Future.wait<dynamic>([
        _api.get('/dashboard'),
        _api.get('/me/progress-summary'),
        GoalApiService().getCurrentGoal().catchError((_) => null),
      ]);

      // ignore: avoid_dynamic_calls
      final dashRes    = results[0];
      // ignore: avoid_dynamic_calls
      final summaryRes = results[1];

      if (dashRes.statusCode == 401 || summaryRes.statusCode == 401) {
        throw Exception('401');
      }

      if (dashRes.statusCode != 200) {
        throw Exception('Erro ao carregar dashboard');
      }

      final dashboard = jsonDecode(dashRes.body as String) as Map<String, dynamic>;
      final summary   = summaryRes.statusCode == 200
          ? jsonDecode(summaryRes.body as String) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _summary   = summary;
        _goalData  = results[2] as GoalData?;
        _loading   = false;
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
    final int treinosComPontos =
        (data['total_workouts_with_points'] as num?)?.toInt() ?? 0;
    final int treinosSemPontos = totalTreinos - treinosComPontos;

    // weekly_progress: List<bool> (Mon–Sun) — converte para int para o gráfico.
    final List<int> weeklyDays =
        (data['weekly_progress'] as List<dynamic>? ?? List.filled(7, false))
            .map((e) => (e as bool?) == true ? 1 : 0)
            .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCards(totalPresencas, totalTreinos, treinosComPontos, treinosSemPontos),
            const SizedBox(height: 32),
            Text('Treinos esta semana', style: AppTypography.h3),
            const SizedBox(height: 16),
            _buildChart(weeklyDays),
            const SizedBox(height: 32),

            // Meta pessoal
            _buildGoalProgressCard(weeklyDays),
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

            _buildAchievementCard(treinosComPontos),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Summary Cards (existentes)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryCards(
    int presencas,
    int treinos,
    int treinosComPontos,
    int treinosSemPontos,
  ) {
    return Column(
      children: [
        Row(
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
                      'Check-ins',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
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
                      style: AppTypography.h1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text('Treinos totais', style: AppTypography.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GymUpCard(
                child: Column(
                  children: [
                    Text(
                      '$treinosComPontos',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'Com pontos',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
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
                      '$treinosSemPontos',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Sem pontos',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                Text(
                  const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][index % 7],
                  style: AppTypography.caption,
                ),
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
  // Meta pessoal
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildGoalProgressCard(List<int> weeklyDays) {
    // Sem meta definida
    if (_goalData == null) {
      return GymUpCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Meta Pessoal', style: AppTypography.h3),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma meta definida. Defina uma meta para acompanhar seu progresso aqui.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => const CreateGoalPage()))
                    .then((_) => _loadData()),
                icon: const Icon(Icons.add),
                label: const Text('Definir meta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final goal         = _goalData!;
    final workoutsDone = weeklyDays.where((d) => d == 1).length;
    final weeklyGoal   = goal.estimatedWorkoutsPerWeek;
    final progress     = (workoutsDone / weeklyGoal).clamp(0.0, 1.0);

    final deltaKg   = (goal.targetWeight - goal.startWeight).abs();
    final direction = goal.goalType == 'weight_gain' ? 'ganhar' : 'perder';

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GoalSummaryPage()))
          .then((_) => _loadData()),
      child: GymUpCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Meta Pessoal', style: AppTypography.h3),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              goal.goalType == 'consistency'
                  ? 'Consistência de treinos'
                  : '${goal.goalTypeLabel}: $direction ${deltaKg.toStringAsFixed(0)} kg',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // Treinos da semana vs meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Treinos esta semana', style: AppTypography.bodyMedium),
                Text(
                  '$workoutsDone / $weeklyGoal',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: workoutsDone >= weeklyGoal
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  workoutsDone >= weeklyGoal
                      ? AppColors.accent
                      : AppColors.primary,
                ),
              ),
            ),

            // Pesos (apenas se não for consistency)
            if (goal.goalType != 'consistency') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _goalWeightCol(
                      'Peso inicial',
                      '${goal.startWeight.toStringAsFixed(0)} kg',
                      AppColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.textSecondary, size: 20),
                  Expanded(
                    child: _goalWeightCol(
                      'Peso meta',
                      '${goal.targetWeight.toStringAsFixed(0)} kg',
                      AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _goalWeightCol(
                      'Diferença',
                      '${deltaKg.toStringAsFixed(0)} kg',
                      AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],

            // Déficit calórico
            if (goal.estimatedDailyCalorieDeficit != null) ...[
              const SizedBox(height: 16),
              Divider(color: AppColors.textSecondary.withAlpha(40)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${goal.estimatedDailyCalorieDeficit} kcal/dia estimadas',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _goalWeightCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.caption, textAlign: TextAlign.center),
      ],
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
