import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'goal_api_service.dart';
import 'goal_summary_page.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class CreateGoalPage extends StatefulWidget {
  /// Peso inicial em kg para pré-preencher o campo (ex: vindo do perfil).
  final double? initialWeight;

  /// Altura em cm para pré-preencher o campo (ex: vindo do perfil).
  final double? initialHeight;

  const CreateGoalPage({
    super.key,
    this.initialWeight,
    this.initialHeight,
  });

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = GoalApiService();

  String _goalType      = 'weight_loss';
  String _gender        = 'male';
  String _activityLevel = 'moderate';

  late final TextEditingController _startWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _heightCtrl;
  final _ageCtrl    = TextEditingController();
  final _monthsCtrl = TextEditingController();

  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startWeightCtrl = TextEditingController(
      text: widget.initialWeight != null
          ? widget.initialWeight!.toStringAsFixed(0)
          : '',
    );
    _targetWeightCtrl = TextEditingController();
    _heightCtrl = TextEditingController(
      text: widget.initialHeight != null
          ? widget.initialHeight!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _startWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      final preview = await _service.previewGoal({
        'goal_type'      : _goalType,
        'gender'         : _gender,
        'start_weight'   : int.parse(_startWeightCtrl.text),
        'target_weight'  : int.parse(_targetWeightCtrl.text),
        'height'         : int.parse(_heightCtrl.text),
        'age'            : int.parse(_ageCtrl.text),
        'activity_level' : _activityLevel,
        'target_months'  : int.parse(_monthsCtrl.text),
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoalSummaryPage(goal: preview, isPendingSave: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
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
          'Definir Meta',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Banner informativo ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estimativa motivacional baseada em dados corporais. Não substitui acompanhamento médico.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Objetivo ───────────────────────────────────────────────
              _buildSectionLabel('Objetivo'),
              const SizedBox(height: 10),
              _buildOptionSelector(
                options: const {
                  'weight_loss': 'Perda de Peso',
                  'weight_gain': 'Ganho de Peso',
                  'consistency': 'Consistência',
                },
                selected: _goalType,
                onChanged: (v) => setState(() => _goalType = v),
              ),

              const SizedBox(height: 24),

              // ── Sexo ───────────────────────────────────────────────────
              _buildSectionLabel('Sexo biológico'),
              const SizedBox(height: 10),
              _buildOptionSelector(
                options: const {'male': 'Masculino', 'female': 'Feminino'},
                selected: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 24),

              // ── Dados corporais ────────────────────────────────────────
              _buildSectionLabel('Dados corporais'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _startWeightCtrl,
                      label: 'Peso atual (kg)',
                      min: 20,
                      max: 500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _targetWeightCtrl,
                      label: 'Peso meta (kg)',
                      min: 20,
                      max: 500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _heightCtrl,
                      label: 'Altura (cm)',
                      min: 100,
                      max: 250,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _ageCtrl,
                      label: 'Idade',
                      min: 10,
                      max: 120,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Nível de atividade ─────────────────────────────────────
              _buildSectionLabel('Nível de atividade atual'),
              const SizedBox(height: 10),
              _buildActivitySelector(),

              const SizedBox(height: 24),

              // ── Prazo ──────────────────────────────────────────────────
              _buildSectionLabel('Prazo'),
              const SizedBox(height: 10),
              _buildField(
                controller: _monthsCtrl,
                label: 'Prazo em meses',
                min: 1,
                max: 36,
              ),

              const SizedBox(height: 32),

              // ── Erro ───────────────────────────────────────────────────
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
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── CTA ────────────────────────────────────────────────────
              GestureDetector(
                onTap: _loading ? null : _submit,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _loading ? 0.7 : 1.0,
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
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Calcular Estimativa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets de apoio ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      );

  /// Seletor de opções em segmento horizontal (substitui ChoiceChip).
  Widget _buildOptionSelector({
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.entries.map((e) {
          final isSelected = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _kBlue.withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Nível de atividade como cards tap-to-select (substitui RadioGroup).
  Widget _buildActivitySelector() {
    const options = <String, _ActivityOption>{
      'sedentary': _ActivityOption('Sedentário',  'Pouco ou nenhum exercício',  Icons.chair_rounded),
      'light'    : _ActivityOption('Leve',         '1–2 dias por semana',        Icons.directions_walk_rounded),
      'moderate' : _ActivityOption('Moderado',     '3–4 dias por semana',        Icons.directions_run_rounded),
      'intense'  : _ActivityOption('Intenso',      '5+ dias por semana',         Icons.bolt_rounded),
    };

    return Column(
      children: options.entries.map((e) {
        final isSelected = _activityLevel == e.key;
        final opt = e.value;
        return GestureDetector(
          onTap: () => setState(() => _activityLevel = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kBlue.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    opt.icon,
                    size: 18,
                    color: isSelected ? _kBlue : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? _kBlue : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        opt.sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _kBlue,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Obrigatório';
        final n = int.tryParse(v);
        if (n == null) return 'Inválido';
        if (n < min || n > max) return '$min–$max';
        return null;
      },
    );
  }
}

// ─── Dados de opção de nível de atividade ─────────────────────────────────────

class _ActivityOption {
  final String   label;
  final String   sub;
  final IconData icon;

  const _ActivityOption(this.label, this.sub, this.icon);
}
