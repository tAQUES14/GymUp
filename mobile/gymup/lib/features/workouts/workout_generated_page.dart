import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_text_field.dart';

const _kBlue = Color(0xFF2563EB);

// Lightweight model used only in the picker / form.
class _LibraryExercise {
  final int    id;
  final String name;
  final String muscleGroup;

  const _LibraryExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });

  factory _LibraryExercise.fromJson(Map<String, dynamic> j) {
    return _LibraryExercise(
      id:          (j['id'] as num).toInt(),
      name:        j['name'] as String? ?? '',
      muscleGroup: j['muscle_group'] as String? ?? '',
    );
  }
}

// Represents an exercise chosen by the user with custom sets/reps/rest.
class _SelectedExercise {
  final _LibraryExercise exercise;
  int sets = 3;
  int reps = 12;
  int rest = 60;

  _SelectedExercise({required this.exercise});
}

// ─────────────────────────────────────────────────────────────────────────────

class WorkoutGeneratedPage extends StatefulWidget {
  const WorkoutGeneratedPage({super.key});

  @override
  State<WorkoutGeneratedPage> createState() => _WorkoutGeneratedPageState();
}

class _WorkoutGeneratedPageState extends State<WorkoutGeneratedPage> {
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedLevel = 'Iniciante';
  static const _levels  = ['Iniciante', 'Intermediário', 'Avançado'];

  final List<_SelectedExercise> _selected = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ── Exercise picker ───────────────────────────────────────────────────────

  Future<void> _openPicker() async {
    final result = await showModalBottomSheet<_LibraryExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(
        alreadySelectedIds: _selected.map((e) => e.exercise.id).toSet(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selected.add(_SelectedExercise(exercise: result)));
    }
  }

  void _removeExercise(int index) {
    setState(() => _selected.removeAt(index));
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um exercício.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Backend expects `exercise_id`, not `id` — build the body explicitly.
      final body = <String, dynamic>{
        'name':         _nameController.text.trim(),
        'description':  '',
        'duration':     int.tryParse(_durationController.text) ?? 45,
        'level':        _selectedLevel,
        'is_generated': false,
        'exercises': _selected.map((s) => {
          'exercise_id': s.exercise.id,
          'sets':        s.sets,
          'reps':        s.reps,
          'rest':        s.rest,
        }).toList(),
      };

      final response = await ApiService().post('/custom-workouts', body);

      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Erro ao salvar treino.');
      }

      if (!mounted) return;

      // Capture messenger before popping so it's still valid after context leaves the tree.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context); // WorkoutsPage .then((_) => _loadAll()) fires here.
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Treino criado com sucesso!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Criar Treino'),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Workout info ───────────────────────────────────────────────
              _SectionHeader(label: 'Informações do treino'),
              const SizedBox(height: 12),

              GymUpTextField(
                label: 'Nome do treino',
                controller: _nameController,
                hintText: 'Ex: Treino A – Peito e Tríceps',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'Nível',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _levels
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLevel = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GymUpTextField(
                      label: 'Duração (min)',
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      hintText: 'Ex: 45',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Selected exercises ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(label: 'Exercícios'),
                  if (_selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selected.length}',
                        style: AppTypography.caption.copyWith(
                          color: _kBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_selected.isEmpty)
                _EmptyExercises(onAdd: _openPicker)
              else ...[
                ..._selected.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseEntry(
                      index:     i + 1,
                      item:      s,
                      onDelete:  () => _removeExercise(i),
                      onChanged: () => setState(() {}),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _openPicker,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar exercício'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: BorderSide(color: _kBlue.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Save ──────────────────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SALVAR TREINO',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty exercise state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyExercises extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExercises({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, color: _kBlue, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum exercício adicionado',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Busque na biblioteca e monte seu treino.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar exercício'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise entry card (in selected list)
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseEntry extends StatelessWidget {
  final int               index;
  final _SelectedExercise item;
  final VoidCallback      onDelete;
  final VoidCallback      onChanged;

  const _ExerciseEntry({
    required this.index,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.exercise.muscleGroup,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: const Color(0xFFEF4444),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberSpinner(
                  label: 'Séries',
                  value: item.sets,
                  min: 1,
                  max: 10,
                  onChanged: (v) { item.sets = v; onChanged(); },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberSpinner(
                  label: 'Reps',
                  value: item.reps,
                  min: 1,
                  max: 50,
                  onChanged: (v) { item.reps = v; onChanged(); },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberSpinner(
                  label: 'Descanso (s)',
                  value: item.rest,
                  min: 10,
                  max: 300,
                  step: 10,
                  onChanged: (v) { item.rest = v; onChanged(); },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Compact +/- spinner ───────────────────────────────────────────────────────

class _NumberSpinner extends StatelessWidget {
  final String            label;
  final int               value;
  final int               min;
  final int               max;
  final int               step;
  final ValueChanged<int> onChanged;

  const _NumberSpinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpinBtn(
                icon: Icons.remove,
                onTap: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              _SpinBtn(
                icon: Icons.add,
                onTap: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpinBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;

  const _SpinBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? _kBlue : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  final Set<int> alreadySelectedIds;

  const _ExercisePickerSheet({required this.alreadySelectedIds});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchController = TextEditingController();

  List<_LibraryExercise> _all      = [];
  List<_LibraryExercise> _filtered = [];
  bool    _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService().get('/exercises');
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode != 200) throw Exception('Erro ao carregar exercícios.');

      final body = jsonDecode(response.body);
      final list = body is List
          ? body
          : (body as Map<String, dynamic>)['data'] as List? ?? <dynamic>[];

      final exercises = list
          .map((e) => _LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _all       = exercises;
        _filtered  = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _all.where((e) {
        return e.name.toLowerCase().contains(q) ||
               e.muscleGroup.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Biblioteca de exercícios',
                  style: AppTypography.h3.copyWith(fontSize: 16),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar exercício ou grupo muscular',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum exercício encontrado.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final ex          = _filtered[i];
                              final alreadyAdded = widget.alreadySelectedIds.contains(ex.id);
                              return _ExerciseRow(
                                exercise:     ex,
                                alreadyAdded: alreadyAdded,
                                onTap:        alreadyAdded
                                    ? null
                                    : () => Navigator.pop(context, ex),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Row in the picker list ────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final _LibraryExercise exercise;
  final bool             alreadyAdded;
  final VoidCallback?    onTap;

  const _ExerciseRow({
    required this.exercise,
    required this.alreadyAdded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kBlue.withValues(alpha: alreadyAdded ? 0.05 : 0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.fitness_center_rounded,
          size: 18,
          color: _kBlue.withValues(alpha: alreadyAdded ? 0.40 : 1.0),
        ),
      ),
      title: Text(
        exercise.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: alreadyAdded ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        exercise.muscleGroup,
        style: TextStyle(
          fontSize: 12,
          color: alreadyAdded
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF94A3B8),
        ),
      ),
      trailing: alreadyAdded
          ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFFCBD5E1))
          : const Icon(Icons.add_circle_outline_rounded, size: 20, color: _kBlue),
    );
  }
}
