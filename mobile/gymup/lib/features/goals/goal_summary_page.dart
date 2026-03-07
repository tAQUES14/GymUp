import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import 'goal_api_service.dart';
import 'create_goal_page.dart';

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

  GoalData?        _goal;
  List<BodyWeightLog> _weightHistory = [];
  bool      _loading = true;
  bool      _saving  = false;
  String?   _error;

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
        // histórico de peso é não-crítico: falha silenciosa com lista vazia
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
      appBar: const GymUpAppBar(title: 'Minha Meta'),
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const GymUpLoading();

    if (_error != null && _goal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadGoal,
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

    if (_goal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Nenhuma meta definida ainda.',
                  style: AppTypography.h3, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Defina uma meta para acompanhar sua evolução motivacional.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateGoalPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Definir Meta'),
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

    final goal = _goal!;

    return RefreshIndicator(
      onRefresh: _loadGoal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGoalHeader(goal),
            const SizedBox(height: 20),
            _buildWeightProgressCard(goal),
            const SizedBox(height: 16),
            if (goal.estimatedDailyCalorieDeficit != null) ...[
              _buildCalorieCard(goal),
              const SizedBox(height: 16),
            ],
            _buildWorkoutsCard(goal),
            const SizedBox(height: 16),
            _buildDetailsCard(goal),
            const SizedBox(height: 16),
            _buildDisclaimer(),
            const SizedBox(height: 24),

            // Erro ao salvar
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // Botão principal: Salvar (preview) ou Redefinir (já salva)
            if (widget.isPendingSave)
              ElevatedButton(
                onPressed: _saving ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar meta'),
              )
            else
              OutlinedButton.icon(
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
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Redefinir Meta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalHeader(GoalData goal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.goalTypeLabel,
                  style: AppTypography.h2.copyWith(color: Colors.white)),
              Text(
                '${goal.targetMonths} ${goal.targetMonths == 1 ? 'mês' : 'meses'} de prazo',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              if (widget.isPendingSave)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Prévia — ainda não salva',
                    style: AppTypography.caption
                        .copyWith(color: Colors.white60),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightProgressCard(GoalData goal) {
    final currentWeight = _weightHistory.isNotEmpty
        ? _weightHistory.first.weight
        : goal.startWeight;

    final totalDelta = (goal.targetWeight - goal.startWeight).abs();
    final doneDelta  = (currentWeight - goal.startWeight).abs();
    // progresso: 0.0 = início, 1.0 = meta atingida
    final progress = totalDelta > 0
        ? (doneDelta / totalDelta).clamp(0.0, 1.0)
        : 1.0;

    // sentido: perda → current deve ser <= start; ganho → current >= start
    final isLoss = goal.goalType == 'weight_loss';
    final isOnTrack = isLoss
        ? currentWeight <= goal.startWeight
        : currentWeight >= goal.startWeight;

    final progressColor = progress >= 1.0
        ? AppColors.accent
        : (isOnTrack ? AppColors.primary : AppColors.warning);

    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evolução de Peso', style: AppTypography.bodyLarge),
              if (!widget.isPendingSave)
                TextButton.icon(
                  onPressed: () => _showRegisterWeightDialog(goal),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Registrar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Três colunas: Inicial | Atual | Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weightCol('Inicial', '${goal.startWeight.toStringAsFixed(1)} kg',
                  AppColors.textSecondary),
              _weightCol('Atual', '${currentWeight.toStringAsFixed(1)} kg',
                  AppColors.textPrimary),
              _weightCol('Meta', '${goal.targetWeight.toStringAsFixed(1)} kg',
                  AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.textSecondary.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? 'Meta atingida!'
                : '${(progress * 100).toStringAsFixed(0)}% do caminho'
                    ' — faltam ${(totalDelta - doneDelta).abs().toStringAsFixed(1)} kg',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),

          // Histórico resumido (últimas 3 entradas)
          if (_weightHistory.length > 1) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.textSecondary.withAlpha(40)),
            const SizedBox(height: 8),
            ..._weightHistory.take(3).map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(log.recordedAt),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${log.weight.toStringAsFixed(1)} kg',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _showRegisterWeightDialog(GoalData goal) async {
    final ctrl = TextEditingController();
    // Pré-preenche com o peso mais recente
    if (_weightHistory.isNotEmpty) {
      ctrl.text = _weightHistory.first.weight.toStringAsFixed(1);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Peso atual (kg)',
            border: OutlineInputBorder(),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
      _loadGoal(); // recarrega para atualizar o card
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _weightCol(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      );

  Widget _buildCalorieCard(GoalData goal) {
    final deficit = goal.estimatedDailyCalorieDeficit!;
    final label   = goal.goalType == 'weight_loss'
        ? 'Déficit calórico estimado'
        : 'Surplus calórico estimado';
    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: AppColors.warning, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '$deficit kcal/dia',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsCard(GoalData goal) {
    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: AppColors.accent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treinos recomendados', style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '${goal.estimatedWorkoutsPerWeek}x por semana',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(GoalData goal) {
    return GymUpCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dados informados', style: AppTypography.bodyLarge),
          const SizedBox(height: 12),
          _detail('Sexo', goal.genderLabel),
          _detail('Altura', '${goal.height.toStringAsFixed(0)} cm'),
          _detail('Idade', '${goal.age} anos'),
          _detail('Nível de atividade', goal.activityLevelLabel),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            Text(value, style: AppTypography.bodyMedium),
          ],
        ),
      );

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withAlpha(75)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimativa motivacional baseada na fórmula de Mifflin-St Jeor. '
              'Não substitui acompanhamento médico ou nutricional especializado.',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
