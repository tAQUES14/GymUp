import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../home/widgets/daily_workout_card.dart';
import 'models/workout_model.dart';
import 'workout_api_service.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  List<WorkoutModel> _workouts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final workouts = await WorkoutApiService().getWorkouts();
      if (!mounted) return;

      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Treinos'),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const GymUpLoading()
          : _hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Erro ao carregar treinos.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWorkouts,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final firstWorkout = _workouts.isNotEmpty ? _workouts.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Treino do Dia: usa o primeiro treino real do usuário.
          DailyWorkoutCard(
            workoutName: firstWorkout?.name ?? 'Nenhum treino cadastrado',
            duration: firstWorkout != null
                ? '${firstWorkout.duration ?? 0} min'
                : '--',
            level: firstWorkout?.level ?? '--',
            onTap: firstWorkout != null
                ? () => Navigator.pushNamed(
                      context,
                      '/workout-detail',
                      arguments: firstWorkout,
                    )
                : null,
          ),
          const SizedBox(height: 24),

          Text('Meus Treinos', style: AppTypography.h3),
          const SizedBox(height: 12),

          if (_workouts.isEmpty)
            _buildEmptyState()
          else
            ..._workouts.map((workout) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWorkoutCard(workout),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino encontrado.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um treino personalizado para começar.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    return GymUpCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/workout-detail',
          arguments: workout,
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.level ?? ''} • ${workout.duration ?? 0} min',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
