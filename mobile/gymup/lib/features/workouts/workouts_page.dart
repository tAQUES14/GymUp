import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../home/widgets/daily_workout_card.dart';
import 'mocks/workouts_mock.dart';
import 'models/workout_model.dart';
import 'workout_api_service.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await WorkoutApiService().getDashboard();
      if (!mounted) return;

      setState(() {
        _dashboardData = data;
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

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Treinos'),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const GymUpLoading()
          : _hasError || _dashboardData == null
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
            'Erro ao carregar dados.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboard,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Treino do Dia
          DailyWorkoutCard(
            workoutName: WorkoutsMock.standardWorkouts[0].name,
            duration: '${WorkoutsMock.standardWorkouts[0].duration ?? 0} min',
            level: WorkoutsMock.standardWorkouts[0].level ?? '',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/workout-detail',
                arguments: WorkoutsMock.standardWorkouts[0],
              );
            },
          ),
          const SizedBox(height: 24),

          Text('Treinos Padrão', style: AppTypography.h3),
          const SizedBox(height: 12),

          ...WorkoutsMock.standardWorkouts.map((workout) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWorkoutCard(workout),
            );
          }),
        ],
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