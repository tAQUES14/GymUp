import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'goal_api_service.dart';
import 'goal_summary_page.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kBlue2 = Color(0xFF4A8CFF);
const _kBlueSoft = Color(0xFFE7EEFE);
const _kRed = Color(0xFFD14343);

class CreateGoalPage extends StatefulWidget {
  final double? initialWeight;
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

  String _goalType = 'weight_loss';
  String _gender = 'male';
  String _activityLevel = 'moderate';
  bool _loading = false;
  String? _error;

  late final TextEditingController _startWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _heightCtrl;
  final _ageCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '6');

  @override
  void initState() {
    super.initState();
    _startWeightCtrl = TextEditingController(
      text: widget.initialWeight != null ? widget.initialWeight!.toStringAsFixed(0) : '',
    );
    _targetWeightCtrl = TextEditingController();
    _heightCtrl = TextEditingController(
      text: widget.initialHeight != null ? widget.initialHeight!.toStringAsFixed(0) : '',
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
      _error = null;
    });

    try {
      final preview = await _service.previewGoal({
        'goal_type': _goalType,
        'gender': _gender,
        'start_weight': int.parse(_startWeightCtrl.text),
        'target_weight': int.parse(_targetWeightCtrl.text),
        'height': int.parse(_heightCtrl.text),
        'age': int.parse(_ageCtrl.text),
        'activity_level': _activityLevel,
        'target_months': int.parse(_monthsCtrl.text),
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
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 118 + bottomInset),
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 14),
                  const _InfoBanner(),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'OBJETIVO',
                    child: _Segmented(
                      selected: _goalType,
                      items: const {
                        'weight_loss': 'Perda',
                        'weight_gain': 'Ganho',
                        'consistency': 'Consist\u00EAncia',
                      },
                      onChanged: (value) => setState(() => _goalType = value),
                    ),
                  ),
                  _Section(
                    title: 'SEXO BIOL\u00D3GICO',
                    child: _Segmented(
                      selected: _gender,
                      items: const {'male': 'Masculino', 'female': 'Feminino'},
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                  ),
                  _Section(
                    title: 'DADOS CORPORAIS',
                    child: _BodyDataCard(
                      startWeightCtrl: _startWeightCtrl,
                      targetWeightCtrl: _targetWeightCtrl,
                      heightCtrl: _heightCtrl,
                      ageCtrl: _ageCtrl,
                    ),
                  ),
                  _ActivitySection(
                    selected: _activityLevel,
                    onChanged: (value) => setState(() => _activityLevel = value),
                  ),
                  _Section(
                    title: 'PRAZO',
                    child: _SingleInputCard(
                      controller: _monthsCtrl,
                      label: 'PRAZO EM MESES',
                      unit: 'meses',
                      icon: Icons.event_rounded,
                      min: 1,
                      max: 36,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 2),
                    _ErrorBox(message: _error!),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomCta(
                bottomInset: bottomInset,
                loading: _loading,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _shadow(tight: true),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _kInk, size: 20),
          ),
        ),
        Expanded(
          child: Text(
            'Definir Meta',
            textAlign: TextAlign.center,
            style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _kBlueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.info_outline_rounded, color: _kBlue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Estimativa motivacional baseada em dados corporais.',
                    style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kInk, height: 1.5),
                  ),
                  TextSpan(
                    text: ' N\u00E3o substitui acompanhamento m\u00E9dico.',
                    style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.5),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _pjs(size: 13, weight: FontWeight.w800, color: _kInk, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String selected;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _Segmented({
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: items.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _kBlue.withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: isSelected ? Colors.white : _kMuted,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BodyDataCard extends StatelessWidget {
  final TextEditingController startWeightCtrl;
  final TextEditingController targetWeightCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController ageCtrl;

  const _BodyDataCard({
    required this.startWeightCtrl,
    required this.targetWeightCtrl,
    required this.heightCtrl,
    required this.ageCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GoalInput(
                  controller: startWeightCtrl,
                  label: 'PESO ATUAL',
                  unit: 'kg',
                  icon: Icons.monitor_weight_outlined,
                  min: 20,
                  max: 500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalInput(
                  controller: targetWeightCtrl,
                  label: 'PESO META',
                  unit: 'kg',
                  icon: Icons.flag_rounded,
                  min: 20,
                  max: 500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GoalInput(
                  controller: heightCtrl,
                  label: 'ALTURA',
                  unit: 'cm',
                  icon: Icons.height_rounded,
                  min: 100,
                  max: 250,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalInput(
                  controller: ageCtrl,
                  label: 'IDADE',
                  unit: 'anos',
                  icon: Icons.cake_rounded,
                  min: 10,
                  max: 120,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SingleInputCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final int min;
  final int max;

  const _SingleInputCard({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteDecoration(20),
      child: _GoalInput(
        controller: controller,
        label: label,
        unit: unit,
        icon: icon,
        min: min,
        max: max,
      ),
    );
  }
}

class _GoalInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final int min;
  final int max;

  const _GoalInput({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: _pjs(size: 11, weight: FontWeight.w800, color: _kMuted, letterSpacing: 0.4)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: _sg(size: 17, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: _kMuted),
            suffixText: unit,
            suffixStyle: _sg(size: 12, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.3),
            filled: true,
            fillColor: const Color(0xFFF7F9FC),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _kInk.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBlue, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kRed, width: 1.4),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Obrigat\u00F3rio';
            final number = int.tryParse(value);
            if (number == null) return 'Inv\u00E1lido';
            if (number < min || number > max) return '$min-$max';
            return null;
          },
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ActivitySection({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _ActivityOption('sedentary', 'Sedent\u00E1rio', 'Pouco ou nenhum exerc\u00EDcio', Icons.chair_rounded),
      _ActivityOption('light', 'Leve', '1-2 dias por semana', Icons.directions_walk_rounded),
      _ActivityOption('moderate', 'Moderado', '3-4 dias por semana', Icons.directions_run_rounded),
      _ActivityOption('intense', 'Intenso', '5+ dias por semana', Icons.bolt_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'N\u00CDVEL DE ATIVIDADE ATUAL',
                  style: _pjs(size: 13, weight: FontWeight.w800, color: _kInk, letterSpacing: 0.3),
                ),
              ),
              Text(
                'Treinos por semana',
                style: _pjs(size: 11, weight: FontWeight.w600, color: _kSoft, letterSpacing: -0.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityCard(
                option: option,
                selected: selected == option.value,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _kBlue : _kInk.withValues(alpha: 0.07), width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : _shadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? _kBlueSoft : const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: selected ? _kBlue : _kMuted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title, style: _pjs(size: 14.5, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(option.subtitle, style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 22 : 24,
              height: selected ? 22 : 24,
              decoration: BoxDecoration(
                color: selected ? _kBlue : Colors.transparent,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: _kInk.withValues(alpha: 0.18)),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final double bottomInset;
  final bool loading;
  final VoidCallback onTap;

  const _BottomCta({
    required this.bottomInset,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 19, 20, 26 + bottomInset),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kInk.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: loading ? 0.72 : 1,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kBlueDark, _kBlue, _kBlue2]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.36),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calculate_rounded, color: Colors.white, size: 17),
                        const SizedBox(width: 10),
                        Text(
                          'Calcular Estimativa',
                          style: _pjs(size: 15.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRed.withValues(alpha: 0.20)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _pjs(size: 12.5, weight: FontWeight.w600, color: _kRed),
      ),
    );
  }
}

class _ActivityOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityOption(this.value, this.title, this.subtitle, this.icon);
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
