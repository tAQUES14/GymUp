import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import 'goal_api_service.dart';
import 'create_goal_page.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class GoalSummaryPage extends StatefulWidget {
  /// Dados da meta. Se [isPendingSave] for true, ainda não foi persistida.
  final GoalData? goal;

  /// Quando true, exibe o botão "Salvar meta" para confirmar a persistência.
  final bool isPendingSave;

  const GoalSummaryPage({super.key, this.goal, this.isPendingSave = false});

  @override
  State<GoalSummaryPage> createState() => _GoalSummaryPageState();
}

class _GoalSummaryPageState extends State<GoalSummaryPage> {
  final _service = GoalApiService();

  GoalData?           _goal;
  List<BodyWeightLog> _weightHistory = [];
  bool    _loading = true;
  bool    _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _goal    = widget.goal;
      _loading = false;
    } else {
      _loadGoal();
    }
  }

  Future<void> _loadGoal() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getCurrentGoal(),
        _service.getBodyWeightHistory(limit: 12)
            .catchError((_) => <BodyWeightLog>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _goal          = results[0] as GoalData?;
        _weightHistory = results[1] as List<BodyWeightLog>;
        _loading       = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_goal == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _service.createGoal(_goal!.toRequestMap());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meta salva com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error  = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
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
          'Minha Meta',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        titleSpacing: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const GymUpLoading();

    // ── Estado de erro ─────────────────────────────────────────────────────
    if (_error != null && _goal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 34, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text('Sem conexão', style: AppTypography.h3),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadGoal,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Estado vazio ───────────────────────────────────────────────────────
    if (_goal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, size: 38, color: _kBlue),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhuma meta definida',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Defina uma meta para acompanhar\nsua evolução motivacional.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateGoalPage()),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Definir Meta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final goal = _goal!;

    return RefreshIndicator(
      onRefresh: _loadGoal,
      color: _kBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Hero ──────────────────────────────────────────────────────
            _buildHero(goal),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Progresso de peso ────────────────────────────────
                  _buildWeightCard(goal),

                  const SizedBox(height: 14),

                  // ── Estimativas (calorias + treinos) ─────────────────
                  Row(
                    children: [
                      if (goal.estimatedDailyCalorieDeficit != null)
                        Expanded(child: _buildCalorieCard(goal)),
                      if (goal.estimatedDailyCalorieDeficit != null)
                        const SizedBox(width: 12),
                      Expanded(child: _buildWorkoutsCard(goal)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Dados informados ─────────────────────────────────
                  _buildDetailsCard(goal),

                  const SizedBox(height: 14),

                  // ── Disclaimer ────────────────────────────────────────
                  _buildDisclaimer(),

                  const SizedBox(height: 28),

                  // ── Erro ao salvar ────────────────────────────────────
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── CTA ───────────────────────────────────────────────
                  if (widget.isPendingSave)
                    _buildSaveButton()
                  else
                    _buildRedefineButton(goal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero com gradiente azul ────────────────────────────────────────────────

  Widget _buildHero(GoalData goal) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlueDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de meta
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.goalTypeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goal.targetMonths} ${goal.targetMonths == 1 ? 'mês' : 'meses'} de prazo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPendingSave)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    'Prévia',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats de peso
          Row(
            children: [
              _heroStat('${goal.startWeight.toStringAsFixed(1)} kg', 'Início'),
              _heroDivider(),
              _heroStat('${goal.targetWeight.toStringAsFixed(1)} kg', 'Meta'),
              _heroDivider(),
              _heroStat(
                '${(goal.targetWeight - goal.startWeight).abs().toStringAsFixed(1)} kg',
                goal.goalType == 'weight_loss' ? 'A perder' : 'A ganhar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _heroDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.20),
      );

  // ── Card de progresso de peso ──────────────────────────────────────────────

  Widget _buildWeightCard(GoalData goal) {
    final currentWeight = _weightHistory.isNotEmpty
        ? _weightHistory.first.weight
        : goal.startWeight;

    final totalDelta = (goal.targetWeight - goal.startWeight).abs();
    final doneDelta  = (currentWeight - goal.startWeight).abs();
    final progress   = totalDelta > 0
        ? (doneDelta / totalDelta).clamp(0.0, 1.0)
        : 1.0;

    final isLoss     = goal.goalType == 'weight_loss';
    final isOnTrack  = isLoss
        ? currentWeight <= goal.startWeight
        : currentWeight >= goal.startWeight;

    final progressColor = progress >= 1.0
        ? const Color(0xFF10B981)
        : (isOnTrack ? _kBlue : AppColors.warning);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.monitor_weight_rounded, color: _kBlue, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Evolução de Peso',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (!widget.isPendingSave)
                GestureDetector(
                  onTap: () => _showRegisterWeightDialog(goal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: _kBlue),
                        const SizedBox(width: 3),
                        Text(
                          'Registrar',
                          style: AppTypography.caption.copyWith(
                            color: _kBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Três colunas: Inicial | Atual | Meta
          Row(
            children: [
              _weightCol('Início', goal.startWeight, const Color(0xFF94A3B8)),
              _weightDivider(),
              _weightCol('Atual', currentWeight, const Color(0xFF0F172A)),
              _weightDivider(),
              _weightCol('Meta', goal.targetWeight, _kBlue),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            progress >= 1.0
                ? 'Meta atingida! Parabéns!'
                : '${(progress * 100).toStringAsFixed(0)}% concluído  •  faltam ${(totalDelta - doneDelta).abs().toStringAsFixed(1)} kg',
            style: AppTypography.caption.copyWith(
              color: progressColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Histórico resumido
          if (_weightHistory.length > 1) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Text(
              'Últimos registros',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ..._weightHistory.take(3).map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(log.recordedAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${log.weight.toStringAsFixed(1)} kg',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _weightCol(String label, double value, Color color) => Expanded(
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _weightDivider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFF1F5F9),
      );

  // ── Card de calorias ───────────────────────────────────────────────────────

  Widget _buildCalorieCard(GoalData goal) {
    final deficit = goal.estimatedDailyCalorieDeficit!;
    final isLoss  = goal.goalType == 'weight_loss';
    const orange  = Color(0xFFF97316);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: orange, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$deficit',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
          Text(
            'kcal/dia',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isLoss ? 'Déficit calórico' : 'Surplus calórico',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card de treinos ────────────────────────────────────────────────────────

  Widget _buildWorkoutsCard(GoalData goal) {
    const green = Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: green, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '${goal.estimatedWorkoutsPerWeek}x',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
          Text(
            'por semana',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Treinos recomendados',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card de detalhes ───────────────────────────────────────────────────────

  Widget _buildDetailsCard(GoalData goal) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded, color: _kBlue, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                'Dados informados',
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detail('Sexo',              goal.genderLabel),
          _detail('Altura',            '${goal.height.toStringAsFixed(0)} cm'),
          _detail('Idade',             '${goal.age} anos'),
          _detail('Nível de atividade', goal.activityLevelLabel),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: _kBlue.withValues(alpha: 0.60)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimativa motivacional (Mifflin-St Jeor). '
              'Não substitui acompanhamento médico ou nutricional.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botões ─────────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _saveGoal,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _saving ? 0.7 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Salvar Meta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedefineButton(GoalData goal) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateGoalPage(
            initialWeight: _weightHistory.isNotEmpty
                ? _weightHistory.first.weight
                : _goal?.startWeight,
            initialHeight: _goal?.height,
          ),
        ),
      ),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Redefinir Meta'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBlue,
        side: const BorderSide(color: _kBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Registrar peso ─────────────────────────────────────────────────────────

  Future<void> _showRegisterWeightDialog(GoalData goal) async {
    final ctrl = TextEditingController();
    if (_weightHistory.isNotEmpty) {
      ctrl.text = _weightHistory.first.weight.toStringAsFixed(1);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar peso', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
          ],
          decoration: InputDecoration(
            labelText: 'Peso atual (kg)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBlue, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final weight = double.tryParse(ctrl.text.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso inválido (20–500 kg).')),
      );
      return;
    }

    try {
      await _service.logBodyWeight(weight);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peso registrado!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadGoal();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
