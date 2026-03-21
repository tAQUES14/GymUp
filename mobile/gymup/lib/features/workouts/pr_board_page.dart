import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'workout_api_service.dart';

class PRBoardPage extends StatefulWidget {
  const PRBoardPage({super.key});

  @override
  State<PRBoardPage> createState() => _PRBoardPageState();
}

class _PRBoardPageState extends State<PRBoardPage> {
  final _api = WorkoutApiService();

  bool _loading = true;
  String? _error;
  Map<String, List<ExercisePRRecord>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prs = await _api.getAllPRs();
      if (!mounted) return;

      // Group by muscle_group; empty → "Outros"
      final grouped = <String, List<ExercisePRRecord>>{};
      for (final pr in prs) {
        final group = pr.muscleGroup.isNotEmpty ? pr.muscleGroup : 'Outros';
        grouped.putIfAbsent(group, () => []).add(pr);
      }

      // Sort groups alphabetically
      final sorted = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      setState(() {
        _grouped = sorted;
        _loading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Records Pessoais',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
                onPressed: _load,
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

    if (_grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum record ainda',
                style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete seu primeiro treino para começar a construir seu perfil de atleta.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _grouped.entries.map((entry) {
          return _buildMuscleGroup(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildMuscleGroup(String group, List<ExercisePRRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
          child: Text(
            group.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: List.generate(records.length, (i) {
              final pr = records[i];
              final isLast = i == records.length - 1;

              String fmtKg(double v) => v == v.roundToDouble()
                  ? '${v.toInt()} kg'
                  : '${v.toStringAsFixed(1)} kg';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        // Trophy icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + muscle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pr.exerciseName,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmtKg(pr.maxWeight),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (pr.maxEstimated1RM != null)
                              Text(
                                'e1RM ${fmtKg(pr.maxEstimated1RM!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
