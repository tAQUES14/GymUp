import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_button.dart';
import '../services/firestore_service.dart';
import 'models/workout_model.dart';

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  WorkoutModel? _workout;
  bool _isInit = true;

  final Set<String> _completedExercises = {};

  // UX tokens
  static const _pageBg = Color(0xFFF5F6FA);
  static const _textStrong = Color(0xFF111827);
  static const _textMuted = Color(0xFF6B7280);
  static const _textSoft = Color(0xFF9CA3AF);
  static const _cardBorder = Color(0x0F111827);
  static const _infoBg = Color(0xFFF3F4F6);
  static const _completedBg = Color(0x0D6C63FF);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is WorkoutModel) {
        _workout = args;
        for (var ex in _workout!.exercicios) {
          if (ex.sets.isEmpty) {
            ex.sets.addAll(
              List.generate(
                3,
                (i) => WorkoutSet(number: i + 1, weight: ex.carga, reps: 12),
              ),
            );
          }
        }
        for (var ex in _workout!.exercicios) {
          if (ex.sets.isNotEmpty && ex.sets.every((s) => s.isCompleted)) {
            _completedExercises.add(ex.nome);
          }
        }
      }
      _isInit = false;
    }
  }

  void _toggleExerciseCompletion(ExerciseModel exercise) {
    setState(() {
      if (_completedExercises.contains(exercise.nome)) {
        _completedExercises.remove(exercise.nome);
        for (var s in exercise.sets) {
          s.isCompleted = false;
        }
      } else {
        _completedExercises.add(exercise.nome);
        for (var s in exercise.sets) {
          s.isCompleted = true;
        }
      }
    });
  }

  // ── Lógica de navegação ───────────────────────────────────────────────────

  /// Usa [validouHoje] derivado do StreamBuilder — sem nova leitura do Firestore.
  void _onIniciarTreino(BuildContext context, bool validouHoje) {
    if (_workout == null) return;
    if (validouHoje) {
      Navigator.pushNamed(
        context,
        '/workout-execution-exercise',
        arguments: _workout!,
      );
    } else {
      _showValidacaoModal(context);
    }
  }

  void _showValidacaoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Valide sua presença', style: AppTypography.h3),
        content: Text(
          'Para ganhar pontos, valide o QR Code da academia antes de iniciar o treino.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Treinar sem pontos
              Navigator.pushNamed(
                context,
                '/workout-execution-exercise',
                arguments: _workout!,
              );
            },
            child: Text(
              'Treinar sem pontos',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/checkin');
            },
            child: const Text('Validar agora'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_workout == null) {
      return const Scaffold(
        backgroundColor: _pageBg,
        body: Center(
          child: Text(
            'Erro: Treino não encontrado',
            style: TextStyle(color: _textStrong),
          ),
        ),
      );
    }

    final firestoreService = context.read<FirestoreService>();

    // StreamBuilder único — validouHoje é compartilhado pelo body e pelo FAB
    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.getAlunoStream(),
      builder: (context, snapshot) {
        final data = (snapshot.hasData && snapshot.data!.exists)
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        // Verificação síncrona — sem nova leitura do Firestore.
        // Verdadeiro se validou QR hoje OU se já fez checkin hoje.
        final validouOuFezCheckinHoje =
            firestoreService.qrValidadoHoje(data) ||
            firestoreService.checkinHoje(data);

        return Scaffold(
          backgroundColor: _pageBg,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GymUpButton(
              label: 'INICIAR TREINO',
              onPressed: () =>
                  _onIniciarTreino(context, validouOuFezCheckinHoje),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildMetadataSection(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    itemCount: _workout!.exercicios.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, index) =>
                        _buildExerciseCard(_workout!.exercicios[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: _textStrong),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _cardBorder),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _workout!.nome,
              style: AppTypography.h3.copyWith(
                fontSize: 24,
                color: _textStrong,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: const BorderSide(color: _cardBorder).toBorder(),
          boxShadow: [
            BoxShadow(
              color: const Color(0x14111827),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetadataItem(
              Icons.timer_outlined,
              '${_workout!.duracao} min',
              'Duração',
            ),
            _buildDivider(),
            _buildMetadataItem(
              Icons.signal_cellular_alt,
              _workout!.nivel,
              'Nível',
            ),
            _buildDivider(),
            _buildMetadataItem(
              Icons.fitness_center,
              '${_workout!.exercicios.length}',
              'Exercícios',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 28, width: 1, color: const Color(0x14111827));

  Widget _buildMetadataItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _textStrong,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption.copyWith(color: _textMuted)),
      ],
    );
  }

  Widget _buildExerciseCard(ExerciseModel exercise) {
    final isCompleted = _completedExercises.contains(exercise.nome);
    final setsCount = exercise.sets.length.toString();
    final firstSet = exercise.sets.isNotEmpty ? exercise.sets.first : null;
    final repsCount = firstSet?.reps.toString() ?? '-';
    final loadValue = (firstSet != null && firstSet.weight > 0)
        ? '${firstSet.weight}kg'
        : '-';
    final restValue = '${exercise.tempoDescanso}s';
    final cardBg = isCompleted ? _completedBg : Colors.white;
    final titleColor = isCompleted
        ? _textStrong.withValues(alpha: 0.75)
        : _textStrong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted ? AppColors.primary : _cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14111827),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.descricao.isNotEmpty
                          ? exercise.descricao
                          : 'Exercício',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _textSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: isCompleted,
                onChanged: (_) => _toggleExerciseCompletion(exercise),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.28),
                inactiveThumbColor: const Color(0xFF9CA3AF),
                inactiveTrackColor: const Color(0xFFE5E7EB),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoUnit('Séries', setsCount),
              const SizedBox(width: 12),
              _buildInfoUnit('Repetições', repsCount),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoUnit('Carga', loadValue),
              const SizedBox(width: 12),
              _buildInfoUnit('Descanso', restValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoUnit(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: _infoBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x0F111827)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on BorderSide {
  Border toBorder() => Border.fromBorderSide(this);
}
