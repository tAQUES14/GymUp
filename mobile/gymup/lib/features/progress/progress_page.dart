import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/widgets/gymup_loading.dart';
import '../goals/create_goal_page.dart';
import '../goals/goal_api_service.dart';
import '../goals/goal_summary_page.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kBlue2 = Color(0xFF4A8CFF);
const _kBlueSoft = Color(0xFFE7EEFE);
const _kLime = Color(0xFFC8F84A);
const _kGreen = Color(0xFF0E9F6E);
const _kGreenSoft = Color(0xFFEAF8EF);
const _kGold = Color(0xFFE5A300);
const _kGoldSoft = Color(0xFFFFF8E1);
const _kOrangeSoft = Color(0xFFFFF4E4);
const _kRed = Color(0xFFD14343);

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _api = ApiService();

  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _summary;
  GoalData? _goalData;
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

      final dashRes = results[0];
      final summaryRes = results[1];

      if (dashRes.statusCode == 401 || summaryRes.statusCode == 401) {
        throw Exception('401');
      }
      if (dashRes.statusCode != 200) {
        throw Exception('Erro ao carregar dados');
      }

      final dashboard = jsonDecode(dashRes.body) as Map<String, dynamic>;
      final summary = summaryRes.statusCode == 200
          ? jsonDecode(summaryRes.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _summary = summary;
        _goalData = results[2] as GoalData?;
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const GymUpLoading()
            : RefreshIndicator(
                color: _kBlue,
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 34 + bottomInset),
                  children: [
                    _Header(
                      onBack: () => Navigator.pop(context),
                      onRefresh: _loadData,
                    ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      _StateCard(
                        icon: Icons.wifi_off_rounded,
                        title: 'Erro ao carregar',
                        subtitle: _error!,
                        color: _kRed,
                        actionLabel: 'Tentar novamente',
                        onAction: _loadData,
                      )
                    else
                      _content(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final data = _dashboard ?? {};
    final summary = _summary ?? {};

    final totalCheckins = _int(data['total_checkins']);
    final totalWorkouts = _int(data['total_workouts']);
    final workoutsWithPoints = _int(data['total_workouts_with_points']);
    final workoutsWithoutPoints =
        (totalWorkouts - workoutsWithPoints).clamp(0, totalWorkouts).toInt();
    final weeklyDays = _weeklyDays(data['weekly_progress'] as List<dynamic>? ?? []);
    final trainedThisWeek = weeklyDays.where((trained) => trained).length;
    final weeklyGoal = _goalData?.estimatedWorkoutsPerWeek ?? 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvolutionHero(
          checkins: totalCheckins,
          workouts: totalWorkouts,
          workoutsWithPoints: workoutsWithPoints,
          workoutsWithoutPoints: workoutsWithoutPoints,
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Frequ\u00EAncia semanal',
          trailing: '$trainedThisWeek / $weeklyGoal dias',
        ),
        const SizedBox(height: 10),
        _WeeklyCard(
          weeklyDays: weeklyDays,
          trained: trainedThisWeek,
          goal: weeklyGoal,
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Minha Meta'),
        const SizedBox(height: 10),
        _GoalCard(
          goal: _goalData,
          workoutsDone: trainedThisWeek,
          onCreate: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CreateGoalPage()))
              .then((_) => _loadData()),
          onOpen: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const GoalSummaryPage()))
              .then((_) => _loadData()),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Performance'),
        const SizedBox(height: 10),
        _PerformanceCard(summary: summary),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Conquistas',
          actionLabel: 'Ver todas',
          onAction: () => Navigator.pushNamed(context, '/achievements'),
        ),
        const SizedBox(height: 10),
        _AchievementPreview(totalWorkoutsWithPoints: workoutsWithPoints),
      ],
    );
  }

  List<bool> _weeklyDays(List<dynamic> rawProgress) {
    final trainedByDow = <int, bool>{};
    for (final entry in rawProgress) {
      if (entry is Map<String, dynamic>) {
        trainedByDow[_int(entry['day_of_week'], fallback: -1)] = entry['trained'] == true;
      }
    }
    const weekDisplayOrder = [1, 2, 3, 4, 5, 6, 0];
    return weekDisplayOrder.map((dow) => trainedByDow[dow] ?? false).toList();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Text(
            'Meu Progresso',
            textAlign: TextAlign.center,
            style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk),
          ),
        ),
        _CircleButton(icon: Icons.refresh_rounded, onTap: onRefresh),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _shadow(tight: true),
        ),
        child: Icon(icon, color: _kInk, size: 19),
      ),
    );
  }
}

class _EvolutionHero extends StatelessWidget {
  final int checkins;
  final int workouts;
  final int workoutsWithPoints;
  final int workoutsWithoutPoints;

  const _EvolutionHero({
    required this.checkins,
    required this.workouts,
    required this.workoutsWithPoints,
    required this.workoutsWithoutPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.13, -0.03),
          end: Alignment(0.77, 0.83),
          colors: [_kBlueDark, _kBlue, _kBlue2],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: _shadow(color: _kBlue.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUA EVOLU\u00C7\u00C3O',
                      style: _pjs(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.84),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$checkins',
                          style: _sg(size: 64, weight: FontWeight.w700, color: Colors.white, height: 0.95),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('check-ins', style: _sg(size: 14, weight: FontWeight.w700, color: Colors.white)),
                              Text('totais na academia', style: _pjs(size: 13, weight: FontWeight.w500, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMetric(value: '$workouts', label: 'TREINOS', color: Colors.white),
              _HeroDivider(),
              _HeroMetric(value: '$workoutsWithPoints', label: 'COM PONTOS', color: _kLime),
              _HeroDivider(),
              _HeroMetric(value: '$workoutsWithoutPoints', label: 'SEM PONTOS', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeroMetric({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: _sg(size: 22, weight: FontWeight.w700, color: color, height: 1)),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _pjs(size: 10, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.78), letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk)),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _kBlueSoft, borderRadius: BorderRadius.circular(100)),
            child: Text(trailing!, style: _sg(size: 12, weight: FontWeight.w700, color: _kBlueDark)),
          ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: _pjs(size: 13, weight: FontWeight.w700, color: _kBlue)),
          ),
      ],
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  final List<bool> weeklyDays;
  final int trained;
  final int goal;

  const _WeeklyCard({
    required this.weeklyDays,
    required this.trained,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'S\u00E1b', 'Dom'];
    final remaining = (goal - trained).clamp(0, goal);

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final done = index < weeklyDays.length && weeklyDays[index];
              return _WeekDay(label: days[index], done: done);
            }),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: remaining == 0 ? _kGreenSoft : _kOrangeSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: remaining == 0 ? 'Meta semanal atingida' : 'Faltam ',
                    style: _pjs(size: 12.5, weight: FontWeight.w600, color: remaining == 0 ? _kGreen : const Color(0xFF7A4500)),
                  ),
                  if (remaining > 0)
                    TextSpan(
                      text: '$remaining treino${remaining == 1 ? '' : 's'}',
                      style: _pjs(size: 12.5, weight: FontWeight.w800, color: _kInk),
                    ),
                  if (remaining > 0)
                    TextSpan(
                      text: ' para a meta desta semana',
                      style: _pjs(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF7A4500)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String label;
  final bool done;

  const _WeekDay({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: done ? _kBlue : const Color(0xFFF1F4F8),
            shape: BoxShape.circle,
            boxShadow: done ? _shadow(color: _kBlue.withValues(alpha: 0.18), tight: true) : null,
          ),
          child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 17) : null,
        ),
        const SizedBox(height: 7),
        Text(label, style: _pjs(size: 10.5, weight: FontWeight.w700, color: done ? _kInk : _kSoft, letterSpacing: 0.2)),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalData? goal;
  final int workoutsDone;
  final VoidCallback onCreate;
  final VoidCallback onOpen;

  const _GoalCard({
    required this.goal,
    required this.workoutsDone,
    required this.onCreate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (goal == null) {
      return _Card(
        child: Column(
          children: [
            Row(
              children: [
                _IconBox(icon: Icons.flag_outlined, color: _kBlue, bg: _kBlueSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nenhuma meta definida', style: _pjs(size: 15, weight: FontWeight.w800, color: _kInk)),
                      const SizedBox(height: 3),
                      Text('Defina uma meta para acompanhar sua evolu\u00E7\u00E3o.', style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kBlueDark, _kBlue, _kBlue2]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _shadow(color: _kBlue.withValues(alpha: 0.22), tight: true),
                ),
                child: Center(child: Text('Definir meta', style: _pjs(size: 12.5, weight: FontWeight.w800, color: Colors.white))),
              ),
            ),
          ],
        ),
      );
    }

    final activeGoal = goal!;
    final weeklyGoal = activeGoal.estimatedWorkoutsPerWeek;
    final progress = weeklyGoal == 0 ? 0.0 : (workoutsDone / weeklyGoal).clamp(0.0, 1.0);
    final deltaKg = (activeGoal.targetWeight - activeGoal.startWeight).abs();
    final isConsistency = activeGoal.goalType == 'consistency';
    final direction = activeGoal.goalType == 'weight_gain' ? 'ganhar' : 'perder';
    final title = isConsistency
        ? 'Consist\u00EAncia de treinos'
        : '${_goalTypeLabel(activeGoal.goalType)}: $direction ${deltaKg.toStringAsFixed(0)} kg';

    return GestureDetector(
      onTap: onOpen,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBox(icon: Icons.flag_rounded, color: _kGreen, bg: _kGreenSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meta Pessoal', style: _pjs(size: 15, weight: FontWeight.w800, color: _kInk)),
                      const SizedBox(height: 3),
                      Text(title, style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _kSoft, size: 20),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Treinos esta semana', style: _pjs(size: 12.5, weight: FontWeight.w600, color: _kMuted)),
                Text('$workoutsDone / $weeklyGoal', style: _sg(size: 13, weight: FontWeight.w700, color: _kBlue)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0x0F0E1116),
                valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
              ),
            ),
            if (!isConsistency) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _WeightPill(label: 'In\u00EDcio', value: '${activeGoal.startWeight.toStringAsFixed(0)} kg'),
                  const Expanded(child: Divider(color: Color(0x1F0E1116), thickness: 1)),
                  _WeightPill(label: 'Meta', value: '${activeGoal.targetWeight.toStringAsFixed(0)} kg', color: _kBlue),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeightPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeightPill({required this.label, required this.value, this.color = _kInk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(value, style: _sg(size: 15, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: _pjs(size: 10.5, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _PerformanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final deltaPct = (summary['overall_delta_pct'] as num?)?.toDouble();
    final deltaAbs = (summary['overall_delta_abs'] as num?)?.toDouble();

    if (deltaPct == null || deltaAbs == null) {
      return _Card(
        child: Row(
          children: [
            _IconBox(icon: Icons.trending_up_rounded, color: _kSoft, bg: const Color(0xFFEFF3F8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evolu\u00E7\u00E3o 30 dias', style: _pjs(size: 14, weight: FontWeight.w700, color: _kInk)),
                  const SizedBox(height: 3),
                  Text('Sem dados suficientes ainda', style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final positive = deltaPct >= 0;
    final color = positive ? _kGreen : _kRed;
    final sign = positive ? '+' : '';

    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evolu\u00E7\u00E3o 30 dias', style: _pjs(size: 14, weight: FontWeight.w700, color: _kInk)),
                const SizedBox(height: 8),
                Text('$sign${deltaPct.toStringAsFixed(1)}%', style: _sg(size: 34, weight: FontWeight.w700, color: color, height: 1)),
                const SizedBox(height: 5),
                Text('$sign${deltaAbs.toStringAsFixed(1)} kg e1RM m\u00E9dio', style: _pjs(size: 12, weight: FontWeight.w600, color: color)),
              ],
            ),
          ),
          _IconBox(
            icon: positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            bg: color.withValues(alpha: 0.10),
            size: 56,
            iconSize: 28,
          ),
        ],
      ),
    );
  }
}

class _AchievementPreview extends StatelessWidget {
  final int totalWorkoutsWithPoints;

  const _AchievementPreview({required this.totalWorkoutsWithPoints});

  @override
  Widget build(BuildContext context) {
    final milestone = ((totalWorkoutsWithPoints / 20).floor() + 1) * 20;
    final progressCount = totalWorkoutsWithPoints % 20;
    final progress = progressCount / 20.0;

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: Icons.emoji_events_rounded, color: _kGold, bg: _kGoldSoft, size: 52, iconSize: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PR\u00D3XIMA CONQUISTA', style: _pjs(size: 10.5, weight: FontWeight.w800, color: _kSoft, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('Maratonista', style: _pjs(size: 15, weight: FontWeight.w800, color: _kInk, height: 1.15)),
                const SizedBox(height: 3),
                Text('Complete $milestone treinos para o pr\u00F3ximo badge.', style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.4)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$progressCount', style: _sg(size: 12, weight: FontWeight.w700, color: _kInk)),
                          TextSpan(text: ' / 20', style: _sg(size: 12, weight: FontWeight.w700, color: _kSoft)),
                          TextSpan(text: ' treinos', style: _sg(size: 12, weight: FontWeight.w700, color: _kMuted)),
                        ],
                      ),
                    ),
                    Text('${(progress * 100).round()}%', style: _sg(size: 12, weight: FontWeight.w700, color: _kBlue)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0x0F0E1116),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0F0E1116)),
        boxShadow: _shadow(),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double iconSize;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.bg,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.30)),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color, bg: color.withValues(alpha: 0.10)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _pjs(size: 14.5, weight: FontWeight.w800, color: _kInk)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onAction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(actionLabel!, style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

int _int(dynamic value, {int fallback = 0}) {
  return (value as num?)?.toInt() ?? fallback;
}

String _goalTypeLabel(String value) {
  return switch (value) {
    'weight_loss' => 'Perda de Peso',
    'weight_gain' => 'Ganho de Peso',
    'consistency' => 'Consist\u00EAncia',
    _ => value,
  };
}

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  required Color color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _sg({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontFamily: 'Space Grotesk',
    fontWeight: weight,
    height: height,
  );
}

List<BoxShadow> _shadow({Color? color, bool tight = false}) {
  return [
    BoxShadow(
      color: color ?? const Color(0x0A0F172A),
      blurRadius: tight ? 8 : 6,
      offset: const Offset(0, 2),
    ),
    if (!tight)
      const BoxShadow(
        color: Color(0x0F0F172A),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
  ];
}
