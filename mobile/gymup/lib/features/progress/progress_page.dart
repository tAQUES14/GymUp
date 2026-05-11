import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../goals/goal_api_service.dart';
import '../goals/goal_summary_page.dart';
import '../goals/create_goal_page.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGreen    = Color(0xFF10B981);
const _kAmber    = Color(0xFFF59E0B);
const _kOrange   = Color(0xFFF97316);

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
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
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
      if (dashRes.statusCode != 200) throw Exception('Erro ao carregar dados');

      final dashboard = jsonDecode(dashRes.body) as Map<String, dynamic>;
      final summary   = summaryRes.statusCode == 200
          ? jsonDecode(summaryRes.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _summary   = summary;
        _goalData  = results[2] as GoalData?;
        _loading   = false;
      });
    } catch (e) {
      if (e.toString().contains('401') && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Meu Progresso',
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
                    gradient: const LinearGradient(
                        colors: [_kBlue, _kBlueDark]),
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

    final data    = _dashboard ?? {};
    final summary = _summary   ?? {};

    final int totalCheckins    = (data['total_checkins'] as num?)?.toInt() ?? 0;
    final int totalTreinos     = (data['total_workouts'] as num?)?.toInt() ?? 0;
    final int treinosComPontos = (data['total_workouts_with_points'] as num?)?.toInt() ?? 0;
    final int treinosSemPontos = totalTreinos - treinosComPontos;

    // weekly_progress é uma lista de objetos {day_of_week, trained, ...}.
    // Monta um mapa por dow e extrai em ordem Seg→Dom (dow 1..6, 0).
    final rawProgress = data['weekly_progress'] as List<dynamic>? ?? [];
    final trainedByDow = <int, bool>{};
    for (final e in rawProgress) {
      if (e is Map<String, dynamic>) {
        final trained = e['trained'];
        // ignore: avoid_print
        assert(() { if (trained is! bool && trained != null) { print('[DEBUG] weekly_progress.trained inesperado: ${trained.runtimeType} = $trained'); } return true; }());
        trainedByDow[e['day_of_week'] as int? ?? -1] = trained == true;
      }
    }
    // Exibição: Seg=1, Ter=2, Qua=3, Qui=4, Sex=5, Sáb=6, Dom=0
    const weekDisplayOrder = [1, 2, 3, 4, 5, 6, 0];
    final List<int> weeklyDays =
        weekDisplayOrder.map((dow) => (trainedByDow[dow] ?? false) ? 1 : 0).toList();

    final pr   = summary['latest_pr']    as Map<String, dynamic>?;
    final best = summary['best_exercise'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Hero: Resumo Geral ──────────────────────────────────────
            _buildHeroStats(
                totalCheckins, totalTreinos, treinosComPontos, treinosSemPontos),

            const SizedBox(height: 28),

            // ── Esta semana ─────────────────────────────────────────────
            _sectionLabel('Esta semana'),
            _buildWeekCard(weeklyDays),

            const SizedBox(height: 28),

            // ── Minha Meta ──────────────────────────────────────────────
            _sectionLabel('Minha Meta'),
            _buildGoalCard(weeklyDays),

            const SizedBox(height: 28),

            // ── Performance ─────────────────────────────────────────────
            _sectionLabel('Performance'),
            _buildEvolutionCard(summary),
            if (pr != null || best != null) ...[
              const SizedBox(height: 12),
              _buildHighlightsCard(pr, best),
            ],

            const SizedBox(height: 28),

            // ── Conquistas ───────────────────────────────────────────────
            _sectionLabel('Conquistas'),
            _buildAchievementCard(treinosComPontos),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Hero Stats ────────────────────────────────────────────────────────────

  Widget _buildHeroStats(
      int checkins, int treinos, int comPontos, int semPontos) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Metric principal ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$checkins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check-ins totais',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Stats strip ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _heroStat('$treinos', 'Treinos', Colors.white),
                _stripDivider(),
                _heroStat('$comPontos', 'Com pontos',
                    const Color(0xFFFDE68A)),
                _stripDivider(),
                _heroStat('$semPontos', 'Sem pontos', Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _stripDivider() {
    return Container(
      width: 1, height: 30,
      color: Colors.white.withValues(alpha: 0.20),
    );
  }

  // ── Week Card ─────────────────────────────────────────────────────────────

  Widget _buildWeekCard(List<int> weeklyDays) {
    const days    = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final trained = weeklyDays.where((d) => d == 1).length;
    final goal    = _goalData?.estimatedWorkoutsPerWeek ?? 4;
    final reached = trained >= goal;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Frequência semanal',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: reached
                      ? _kGreen.withValues(alpha: 0.10)
                      : _kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$trained / $goal dias',
                  style: TextStyle(
                      color: reached ? _kGreen : _kBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final done = i < weeklyDays.length && weeklyDays[i] == 1;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: done
                          ? _kBlue
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: done
                          ? [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(days[i],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: done
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: done
                              ? _kBlue
                              : const Color(0xFFCBD5E1))),
                ],
              );
            }),
          ),
          // Feedback message
          if (trained > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: reached
                    ? _kGreen.withValues(alpha: 0.07)
                    : _kBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    reached
                        ? Icons.celebration_rounded
                        : Icons.bolt_rounded,
                    size: 15,
                    color: reached ? _kGreen : _kBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reached
                          ? 'Meta semanal atingida! Excelente!'
                          : 'Falta${goal - trained == 1 ? "" : "m"} ${goal - trained} '
                            'treino${goal - trained == 1 ? "" : "s"} para a meta desta semana.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reached ? _kGreen : _kBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Goal Card ─────────────────────────────────────────────────────────────

  Widget _buildGoalCard(List<int> weeklyDays) {
    if (_goalData == null) {
      return _card(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: _kBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nenhuma meta definida',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text(
                        'Defina uma meta para acompanhar sua evolução.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const CreateGoalPage()))
                  .then((_) => _loadData()),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kBlue, _kBlueDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Definir meta',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
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
    final deltaKg      = (goal.targetWeight - goal.startWeight).abs();
    final direction    = goal.goalType == 'weight_gain' ? 'ganhar' : 'perder';
    final progressColor =
        workoutsDone >= weeklyGoal ? _kGreen : _kBlue;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(
              MaterialPageRoute(builder: (_) => const GoalSummaryPage()))
          .then((_) => _loadData()),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: _kGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meta Pessoal',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text(
                        goal.goalType == 'consistency'
                            ? 'Consistência de treinos'
                            : '${goal.goalTypeLabel}: $direction '
                              '${deltaKg.toStringAsFixed(0)} kg',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFFCBD5E1)),
              ],
            ),
            const SizedBox(height: 20),
            // Weekly progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Treinos esta semana',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B))),
                Text('$workoutsDone / $weeklyGoal',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: progressColor)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            // Weight journey
            if (goal.goalType != 'consistency') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _weightPill('Início',
                        '${goal.startWeight.toStringAsFixed(0)} kg',
                        const Color(0xFF94A3B8)),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                  color: Color(0xFFCBD5E1),
                                  thickness: 1.5),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: Color(0xFFCBD5E1)),
                          ],
                        ),
                      ),
                    ),
                    _weightPill('Meta',
                        '${goal.targetWeight.toStringAsFixed(0)} kg',
                        _kBlue),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${deltaKg.toStringAsFixed(0)} kg',
                        style: const TextStyle(
                            color: _kGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Calories
            if (goal.estimatedDailyCalorieDeficit != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                      Icons.local_fire_department_rounded,
                      color: _kOrange,
                      size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${goal.estimatedDailyCalorieDeficit} kcal/dia estimadas',
                    style: const TextStyle(
                        color: _kOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weightPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  // ── Evolution Card ────────────────────────────────────────────────────────

  Widget _buildEvolutionCard(Map<String, dynamic> summary) {
    final deltaPct = (summary['overall_delta_pct'] as num?)?.toDouble();
    final deltaAbs = (summary['overall_delta_abs'] as num?)?.toDouble();

    if (deltaPct == null || deltaAbs == null) {
      return _card(
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Color(0xFFCBD5E1), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Evolução 30 dias',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 3),
                  Text('Sem dados suficientes ainda.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isPositive = deltaPct >= 0;
    final color      = isPositive ? _kGreen : AppColors.error;
    final bgColor    = isPositive
        ? _kGreen.withValues(alpha: 0.08)
        : AppColors.error.withValues(alpha: 0.08);
    final sign       = isPositive ? '+' : '';
    final icon       = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evolução 30 dias',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                Text(
                  '$sign${deltaPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$sign${deltaAbs.toStringAsFixed(1)} kg e1RM médio',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.80)),
                ),
              ],
            ),
          ),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  // ── Highlights Card (PR + Maior Evolução) ─────────────────────────────────

  Widget _buildHighlightsCard(
    Map<String, dynamic>? pr,
    Map<String, dynamic>? best,
  ) {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (pr != null) _prRow(pr),
          if (pr != null && best != null)
            const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
                indent: 20,
                endIndent: 20),
          if (best != null) _bestExerciseRow(best),
        ],
      ),
    );
  }

  Widget _prRow(Map<String, dynamic> pr) {
    final name   = pr['name']   as String? ?? '';
    final weight = (pr['weight'] as num?)?.toDouble() ?? 0;
    final reps   = (pr['reps']  as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: _kAmber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PR Mais Recente',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8))),
                const SizedBox(height: 3),
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${weight.toStringAsFixed(1)} kg × $reps',
              style: const TextStyle(
                  color: _kAmber,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestExerciseRow(Map<String, dynamic> best) {
    final name     = best['name'] as String? ?? '';
    final deltaPct = (best['delta_pct'] as num?)?.toDouble() ?? 0;
    final sign     = deltaPct >= 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: _kOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maior Evolução',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8))),
                const SizedBox(height: 3),
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sign${deltaPct.toStringAsFixed(1)}%',
              style: const TextStyle(
                  color: _kOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievement Card ──────────────────────────────────────────────────────

  Widget _buildAchievementCard(int totalTreinos) {
    final milestone = ((totalTreinos / 20).floor() + 1) * 20;
    final feitos    = totalTreinos % 20;
    final progresso = feitos / 20.0;

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: _kAmber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Próxima Conquista',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 3),
                Text(
                  'Complete $milestone treinos para o próximo badge.',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$feitos / 20',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                    Text(
                      '${(progresso * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kAmber),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kAmber),
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
