import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/workout_model.dart';

class WorkoutExecutionSimplePage extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutExecutionSimplePage({super.key, required this.workout});

  @override
  State<WorkoutExecutionSimplePage> createState() =>
      _WorkoutExecutionSimplePageState();
}


class _WorkoutExecutionSimplePageState
    extends State<WorkoutExecutionSimplePage> {
  Timer? _timer;
  int _secondsElapsed = 580; // Starts at 00:09:40 as requested
  bool _isRunning = false;

  // Mock Data
  final List<ExerciseItem> _exercises = [
    ExerciseItem(
      title: 'Voador / Peck Deck',
      subtitle: 'Peito',
      sets: '4',
      reps: '12',
      load: '-',
      rest: '60s',
      isCompleted: false,
    ),
    ExerciseItem(
      title: 'Supino Reto',
      subtitle: 'Ombro, Peito',
      sets: '4',
      reps: '12',
      load: '20kg',
      rest: '60s',
      isCompleted: false,
    ),
    ExerciseItem(
      title: 'Tríceps Corda',
      subtitle: 'Tríceps',
      sets: '3',
      reps: '15',
      load: '15kg',
      rest: '45s',
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-start timer or wait for "Iniciar"?
    // Requirement says "Botão flutuante... Iniciar". So likely starts paused.
    // But Timer in AppBar "ex: 00:09:40" might imply it's running or just static example.
    // I will implemented logic to toggle.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
          });
        });
      }
    });
  }

  String get _formattedTime {
    final duration = Duration(seconds: _secondsElapsed);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // Or Colors.grey[100] if not available
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Treino A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formattedTime,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.08),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ), // Bottom padding for FAB
            itemCount: _exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return ExerciseExecutionCard(
                item: _exercises[index],
                onToggle: (value) {
                  setState(() {
                    _exercises[index].isCompleted = value;
                  });
                },
              );
            },
          ),

          // Floating Button
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 56,
                width: 200,
                child: FloatingActionButton.extended(
                  onPressed: _toggleTimer,
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  label: Text(
                    _isRunning ? 'PAUSAR' : 'INICIAR',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseItem {
  final String title;
  final String subtitle;
  final String sets;
  final String reps;
  final String load;
  final String rest;
  bool isCompleted;

  ExerciseItem({
    required this.title,
    required this.subtitle,
    required this.sets,
    required this.reps,
    required this.load,
    required this.rest,
    this.isCompleted = false,
  });
}

class ExerciseExecutionCard extends StatelessWidget {
  final ExerciseItem item;
  final ValueChanged<bool> onToggle;

  const ExerciseExecutionCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail (Icon)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Titles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Switch
              Switch(
                value: item.isCompleted,
                onChanged: onToggle,
                thumbColor: WidgetStateProperty.all(AppColors.primary),
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Row 2: Grid 2x2
          Row(
            children: [
              _buildInfoUnit('Séries', item.sets),
              const SizedBox(width: 12),
              _buildInfoUnit('Repetições', item.reps),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoUnit('Carga', item.load),
              const SizedBox(width: 12),
              _buildInfoUnit('Descanso', item.rest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoUnit(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // Grey 50
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
