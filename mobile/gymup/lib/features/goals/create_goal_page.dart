import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import 'goal_api_service.dart';
import 'goal_summary_page.dart';

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
  final _ageCtrl   = TextEditingController();
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
      appBar: const GymUpAppBar(title: 'Definir Meta'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sua meta motivacional', style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                'Esta é uma estimativa para motivação. Não substitui acompanhamento médico ou nutricional.',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('Objetivo'),
              _buildChips(
                options: const {
                  'weight_loss': 'Perda de Peso',
                  'weight_gain': 'Ganho de Peso',
                  'consistency': 'Consistência',
                },
                selected: _goalType,
                onChanged: (v) => setState(() => _goalType = v),
              ),
              const SizedBox(height: 20),

              _buildSectionLabel('Sexo biológico'),
              _buildChips(
                options: const {'male': 'Masculino', 'female': 'Feminino'},
                selected: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 16),

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
              const SizedBox(height: 20),

              _buildSectionLabel('Nível de atividade atual'),
              _buildActivitySelector(),
              const SizedBox(height: 20),

              _buildField(
                controller: _monthsCtrl,
                label: 'Prazo em meses',
                min: 1,
                max: 36,
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Calcular Estimativa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTypography.bodyLarge),
      );

  Widget _buildChips({
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return ChoiceChip(
          label: Text(e.value),
          selected: isSelected,
          onSelected: (_) => onChanged(e.key),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySelector() {
    const options = {
      'sedentary': 'Sedentário',
      'light'    : 'Leve',
      'moderate' : 'Moderado',
      'intense'  : 'Intenso',
    };
    return RadioGroup<String>(
      groupValue: _activityLevel,
      onChanged: (v) => setState(() => _activityLevel = v!),
      child: Column(
        children: options.entries.map((e) {
          final isSelected = _activityLevel == e.key;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.value, style: AppTypography.bodyMedium),
            leading: Radio<String>(
              value: e.key,
              activeColor: AppColors.primary,
            ),
            onTap: () => setState(() => _activityLevel = e.key),
            selected: isSelected,
          );
        }).toList(),
      ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
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
