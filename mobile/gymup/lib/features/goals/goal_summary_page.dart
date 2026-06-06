import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/gymup_loading.dart';
import 'create_goal_page.dart';
import 'goal_api_service.dart';

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
const _kRed = Color(0xFFD14343);

class GoalSummaryPage extends StatefulWidget {
  final GoalData? goal;
  final bool isPendingSave;

  const GoalSummaryPage({
    super.key,
    this.goal,
    this.isPendingSave = false,
  });

  @override
  State<GoalSummaryPage> createState() => _GoalSummaryPageState();
}

class _GoalSummaryPageState extends State<GoalSummaryPage> {
  final _service = GoalApiService();

  GoalData? _goal;
  List<BodyWeightLog> _weightHistory = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _goal = widget.goal;
      _loading = false;
      if (!widget.isPendingSave) _loadWeightHistory();
    } else {
      _loadGoal();
    }
  }

  Future<void> _loadGoal() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.getCurrentGoal(),
        _service.getBodyWeightHistory(limit: 12).catchError((_) => <BodyWeightLog>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _goal = results[0] as GoalData?;
        _weightHistory = results[1] as List<BodyWeightLog>;
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

  Future<void> _loadWeightHistory() async {
    try {
      final history = await _service.getBodyWeightHistory(limit: 12);
      if (!mounted) return;
      setState(() => _weightHistory = history);
    } catch (_) {}
  }

  Future<void> _saveGoal() async {
    final goal = _goal;
    if (goal == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.createGoal(goal.toRequestMap());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meta salva com sucesso!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final goal = _goal;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const GymUpLoading()
            : Stack(
                children: [
                  RefreshIndicator(
                    color: _kBlue,
                    onRefresh: widget.isPendingSave ? () async {} : _loadGoal,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        (widget.isPendingSave ? 124 : 34) + bottomInset,
                      ),
                      children: [
                        _Header(
                          title: widget.isPendingSave ? 'Confirmar Meta' : 'Minha Meta',
                          onBack: () => Navigator.pop(context),
                          onEdit: goal == null
                              ? null
                              : () => _openCreateGoal(
                                    initialWeight: _currentWeight(goal),
                                    initialHeight: goal.height,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        if (_error != null && goal == null)
                          _StateCard(
                            icon: Icons.wifi_off_rounded,
                            title: 'Erro ao carregar',
                            subtitle: _error!,
                            actionLabel: 'Tentar novamente',
                            onAction: _loadGoal,
                          )
                        else if (goal == null)
                          _EmptyGoalCard(onCreate: () => _openCreateGoal())
                        else
                          _GoalContent(
                            goal: goal,
                            history: _weightHistory,
                            pending: widget.isPendingSave,
                            error: _error,
                            onRegisterWeight: () => _showRegisterWeightDialog(goal),
                            onRedefine: () => _openCreateGoal(
                              initialWeight: _currentWeight(goal),
                              initialHeight: goal.height,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isPendingSave && goal != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _BottomSaveBar(
                        bottomInset: bottomInset,
                        loading: _saving,
                        onSave: _saveGoal,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  double _currentWeight(GoalData goal) {
    return _weightHistory.isNotEmpty ? _weightHistory.first.weight : goal.startWeight;
  }

  Future<void> _openCreateGoal({double? initialWeight, double? initialHeight}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGoalPage(
          initialWeight: initialWeight,
          initialHeight: initialHeight,
        ),
      ),
    );
    if (!widget.isPendingSave) _loadGoal();
  }

  Future<void> _showRegisterWeightDialog(GoalData goal) async {
    final ctrl = TextEditingController(text: _currentWeight(goal).toStringAsFixed(1));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Registrar peso',
          style: _pjs(size: 18, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.3),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([,.]\d{0,1})?')),
          ],
          decoration: InputDecoration(
            labelText: 'Peso atual (kg)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBlue, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final weight = double.tryParse(ctrl.text.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 500) {
      _snack('Peso invalido. Use um valor entre 20 e 500 kg.');
      return;
    }

    try {
      await _service.logBodyWeight(weight);
      if (!mounted) return;
      _snack('Peso registrado!', success: true);
      _loadGoal();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _kGreen : _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const _Header({
    required this.title,
    required this.onBack,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
          ),
        ),
        onEdit == null
            ? const SizedBox(width: 40)
            : _CircleButton(icon: Icons.edit_rounded, onTap: onEdit!),
      ],
    );
  }
}

class _GoalContent extends StatelessWidget {
  final GoalData goal;
  final List<BodyWeightLog> history;
  final bool pending;
  final String? error;
  final VoidCallback onRegisterWeight;
  final VoidCallback onRedefine;

  const _GoalContent({
    required this.goal,
    required this.history,
    required this.pending,
    required this.error,
    required this.onRegisterWeight,
    required this.onRedefine,
  });

  @override
  Widget build(BuildContext context) {
    final current = history.isNotEmpty ? history.first.weight : goal.startWeight;
    final totalDelta = (goal.targetWeight - goal.startWeight).abs();
    final doneDelta = goal.goalType == 'weight_gain'
        ? (current - goal.startWeight)
        : (goal.startWeight - current);
    final progress = totalDelta <= 0 ? 0.0 : (doneDelta / totalDelta).clamp(0.0, 1.0);
    final remaining = (totalDelta - doneDelta).clamp(0.0, totalDelta);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(goal: goal, progress: progress, currentWeight: current, pending: pending),
        if (error != null) ...[
          const SizedBox(height: 14),
          _InlineError(message: error!),
        ],
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Progresso de peso',
          actionLabel: pending ? null : 'Registrar',
          onAction: pending ? null : onRegisterWeight,
        ),
        const SizedBox(height: 10),
        _WeightProgressCard(
          goal: goal,
          currentWeight: current,
          progress: progress,
          remaining: remaining,
          history: history,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (goal.estimatedDailyCalorieDeficit != null) ...[
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  bg: _kGoldSoft,
                  color: _kGold,
                  value: '${goal.estimatedDailyCalorieDeficit}',
                  label: 'kcal/dia',
                  caption: goal.goalType == 'weight_gain' ? 'Surplus estimado' : 'Deficit estimado',
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _MetricCard(
                icon: Icons.fitness_center_rounded,
                bg: _kGreenSoft,
                color: _kGreen,
                value: '${goal.estimatedWorkoutsPerWeek}x',
                label: 'por semana',
                caption: 'Treinos sugeridos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Dados da meta'),
        const SizedBox(height: 10),
        _DetailsCard(goal: goal),
        const SizedBox(height: 18),
        _DisclaimerCard(),
        if (!pending) ...[
          const SizedBox(height: 18),
          _SecondaryButton(
            label: 'Redefinir Meta',
            icon: Icons.edit_rounded,
            onTap: onRedefine,
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final GoalData goal;
  final double progress;
  final double currentWeight;
  final bool pending;

  const _HeroCard({
    required this.goal,
    required this.progress,
    required this.currentWeight,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final delta = (goal.targetWeight - currentWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlueDark, _kBlue, _kBlue2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending ? 'PREVIEW DA META' : 'MINHA META',
                      style: _pjs(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.78),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _goalTypeLabel(goal.goalType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _pjs(size: 20, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              _Pill(label: '${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                goal.targetWeight.toStringAsFixed(0),
                style: _sg(size: 58, weight: FontWeight.w700, color: Colors.white, height: 0.95, letterSpacing: -2.2),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('kg', style: _sg(size: 16, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.82))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delta <= 0.05
                ? 'Meta praticamente atingida.'
                : 'Faltam ${delta.toStringAsFixed(1)} kg para sua meta.',
            style: _pjs(size: 13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88), height: 1.35),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'ATUAL', value: '${currentWeight.toStringAsFixed(1)} kg')),
              const SizedBox(width: 10),
              Expanded(child: _HeroStat(label: 'PRAZO', value: '${goal.targetMonths} meses')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _pjs(size: 10, weight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.70), letterSpacing: 0.35)),
          const SizedBox(height: 4),
          Text(value, style: _sg(size: 16, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

class _WeightProgressCard extends StatelessWidget {
  final GoalData goal;
  final double currentWeight;
  final double progress;
  final double remaining;
  final List<BodyWeightLog> history;

  const _WeightProgressCard({
    required this.goal,
    required this.currentWeight,
    required this.progress,
    required this.remaining,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          Row(
            children: [
              _WeightCol(label: 'Inicio', value: goal.startWeight, color: _kSoft),
              _Divider(),
              _WeightCol(label: 'Atual', value: currentWeight, color: _kInk),
              _Divider(),
              _WeightCol(label: 'Meta', value: goal.targetWeight, color: _kBlue),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: _kInk.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  progress >= 1
                      ? 'Meta atingida.'
                      : '${(progress * 100).round()}% concluido. Faltam ${remaining.toStringAsFixed(1)} kg.',
                  style: _pjs(size: 12, weight: FontWeight.w700, color: progress >= 1 ? _kGreen : _kMuted, height: 1.35),
                ),
              ),
            ],
          ),
          if (history.length > 1) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: _kInk.withValues(alpha: 0.06)),
            const SizedBox(height: 10),
            for (final log in history.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_formatDate(log.recordedAt), style: _pjs(size: 12, weight: FontWeight.w600, color: _kMuted)),
                    ),
                    Text('${log.weight.toStringAsFixed(1)} kg', style: _sg(size: 12, weight: FontWeight.w700, color: _kInk)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WeightCol extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _WeightCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _sg(size: 18, weight: FontWeight.w700, color: color, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(label, style: _pjs(size: 11, weight: FontWeight.w700, color: _kMuted, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;
  final String value;
  final String label;
  final String caption;

  const _MetricCard({
    required this.icon,
    required this.bg,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteDecoration(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sg(size: 22, weight: FontWeight.w700, color: _kInk, height: 1, letterSpacing: -0.6),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(label, style: _sg(size: 11, weight: FontWeight.w700, color: _kSoft)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(caption, style: _pjs(size: 11.5, weight: FontWeight.w600, color: _kMuted, height: 1.25)),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final GoalData goal;

  const _DetailsCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          _DetailRow(label: 'Objetivo', value: _goalTypeLabel(goal.goalType)),
          _DetailRow(label: 'Sexo biologico', value: goal.gender == 'male' ? 'Masculino' : 'Feminino'),
          _DetailRow(label: 'Altura', value: '${goal.height.toStringAsFixed(0)} cm'),
          _DetailRow(label: 'Idade', value: '${goal.age} anos'),
          _DetailRow(label: 'Atividade', value: _activityLabel(goal.activityLevel), showDivider: false),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _pjs(size: 12.5, weight: FontWeight.w600, color: _kMuted))),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 13, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.1),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Container(height: 1, color: _kInk.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyGoalCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyGoalCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      decoration: _whiteDecoration(22),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _kBlueSoft, shape: BoxShape.circle),
            child: const Icon(Icons.flag_rounded, color: _kBlue, size: 30),
          ),
          const SizedBox(height: 18),
          Text('Nenhuma meta definida', style: _pjs(size: 18, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Defina uma meta para acompanhar sua evolucao de forma motivacional.',
            textAlign: TextAlign.center,
            style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          _PrimaryButton(label: 'Definir meta', icon: Icons.add_rounded, onTap: onCreate),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: _whiteDecoration(22),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, color: _kRed, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: _pjs(size: 17, weight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            _PrimaryButton(label: actionLabel!, icon: Icons.refresh_rounded, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  final double bottomInset;
  final bool loading;
  final VoidCallback onSave;

  const _BottomSaveBar({
    required this.bottomInset,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kInk.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: _PrimaryButton(
        label: 'Salvar Meta',
        icon: Icons.check_rounded,
        loading: loading,
        onTap: onSave,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: loading ? 0.72 : 1,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlueDark, _kBlue, _kBlue2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 17),
                      const SizedBox(width: 8),
                      Text(label, style: _pjs(size: 15, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kInk.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _kBlue, size: 17),
            const SizedBox(width: 8),
            Text(label, style: _pjs(size: 14, weight: FontWeight.w800, color: _kBlue, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3)),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: _kBlueSoft, borderRadius: BorderRadius.circular(100)),
              child: Text(actionLabel!, style: _pjs(size: 12, weight: FontWeight.w800, color: _kBlueDark, letterSpacing: -0.1)),
            ),
          ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBlueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.info_outline_rounded, color: _kBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estimativa motivacional baseada em dados corporais. Nao substitui acompanhamento medico ou nutricional.',
              style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: _pjs(size: 12, weight: FontWeight.w700, color: _kRed)),
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

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(label, style: _sg(size: 12, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: _kInk.withValues(alpha: 0.06));
  }
}

String _goalTypeLabel(String type) {
  switch (type) {
    case 'weight_loss':
      return 'Perda de Peso';
    case 'weight_gain':
      return 'Ganho de Peso';
    case 'consistency':
      return 'Consistencia';
    default:
      return type;
  }
}

String _activityLabel(String activity) {
  switch (activity) {
    case 'sedentary':
      return 'Sedentario';
    case 'light':
      return 'Leve';
    case 'moderate':
      return 'Moderado';
    case 'intense':
      return 'Intenso';
    default:
      return activity;
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

BoxDecoration _whiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: _shadow(),
  );
}

List<BoxShadow> _shadow({bool tight = false}) {
  return [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    if (!tight)
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
  ];
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
