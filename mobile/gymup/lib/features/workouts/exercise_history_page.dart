import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'services/exercise_stats_service.dart';

class ExerciseHistoryPage extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseHistoryPage({super.key, required this.exercise});

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  final _statsService = ExerciseStatsService();

  int _selectedSet = 1;

  // Estado de dados
  PersonalRecord? _pr;
  List<ProgressPoint>? _progress;
  ProgressScore? _score;
  List<WeightHistoryEntry>? _history;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _statsService.getPR(widget.exercise.id),
        _statsService.getProgress(widget.exercise.id, setNumber: _selectedSet),
        _statsService.getProgressScore(widget.exercise.id, setNumber: _selectedSet),
        _statsService.getHistory(widget.exercise.id, setNumber: _selectedSet),
      ]);

      if (!mounted) return;
      setState(() {
        _pr = results[0] as PersonalRecord;
        _progress = results[1] as List<ProgressPoint>;
        _score = results[2] as ProgressScore;
        _history = results[3] as List<WeightHistoryEntry>;
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

  /// Recarrega apenas os dados que dependem de set_number (não PR).
  Future<void> _loadSetData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _statsService.getProgress(widget.exercise.id, setNumber: _selectedSet),
        _statsService.getProgressScore(widget.exercise.id, setNumber: _selectedSet),
        _statsService.getHistory(widget.exercise.id, setNumber: _selectedSet),
      ]);

      if (!mounted) return;
      setState(() {
        _progress = results[0] as List<ProgressPoint>;
        _score = results[1] as ProgressScore;
        _history = results[2] as List<WeightHistoryEntry>;
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
          widget.exercise.name,
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
              Text(
                _error!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAll,
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

    return RefreshIndicator(
      onRefresh: () async {
        _statsService.invalidate(widget.exercise.id);
        await _loadAll();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dropdown de série
          _buildSetSelector(),
          const SizedBox(height: 16),

          // PR
          if (_pr != null && !_pr!.isEmpty) ...[
            _buildPRCard(),
            const SizedBox(height: 16),
          ],

          // Progress Score
          if (_score != null && _score!.hasData) ...[
            _buildProgressScoreCard(),
            const SizedBox(height: 16),
          ],

          // Gráfico
          if (_progress != null && _progress!.length >= 2) ...[
            _buildChartCard(),
            const SizedBox(height: 16),
          ],

          // Histórico
          _buildHistorySection(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Set Selector
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSetSelector() {
    return Row(
      children: [
        Text('Série:', style: AppTypography.bodyLarge),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSet,
              items: List.generate(
                widget.exercise.sets,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Série ${i + 1}'),
                ),
              ),
              onChanged: (val) {
                if (val == null || val == _selectedSet) return;
                setState(() => _selectedSet = val);
                _loadSetData();
              },
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PR Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPRCard() {
    final pr = _pr!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Records Pessoais',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _prStat('Maior Peso', '${pr.bestWeight?.toStringAsFixed(1)} kg'),
              _prStat('Maior Reps', '${pr.bestReps}'),
              _prStat('Melhor e1RM', '${pr.bestE1rm?.toStringAsFixed(1)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Progress Score Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildProgressScoreCard() {
    final s = _score!;
    final isPositive = (s.deltaPct ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppColors.accent : AppColors.error,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progressão 30 dias', style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? "+" : ""}${s.deltaPct?.toStringAsFixed(1)}%'
                  '  (${isPositive ? "+" : ""}${s.deltaAbs?.toStringAsFixed(1)} kg e1RM)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.accent : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Chart Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildChartCard() {
    final points = _progress!;

    final spots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].value),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolução e1RM (12 semanas)', style: AppTypography.bodyLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (points.length / 4).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final date = points[idx].weekStartDate;
                        // "2026-02-23" → "23/02"
                        final parts = date.split('-');
                        return Text(
                          '${parts[2]}/${parts[1]}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // History List
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHistorySection() {
    final entries = _history ?? [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histórico', style: AppTypography.bodyLarge),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum registro para esta série.',
                  style: AppTypography.bodyMedium,
                ),
              ),
            )
          else
            ...entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      dateFormat.format(e.createdAt.toLocal()),
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${e.weight.toStringAsFixed(1)} kg',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${e.reps} reps',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
