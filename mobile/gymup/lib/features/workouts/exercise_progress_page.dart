import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'pr_board_page.dart';
import 'workout_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chart mode toggle
// ─────────────────────────────────────────────────────────────────────────────

enum _ChartMode { weight, estimated1RM }

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseProgressPage extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseProgressPage({super.key, required this.exercise});

  @override
  State<ExerciseProgressPage> createState() => _ExerciseProgressPageState();
}

class _ExerciseProgressPageState extends State<ExerciseProgressPage> {
  final _api = WorkoutApiService();

  bool _loading = true;
  String? _error;

  ExerciseLastSets? _lastSets;
  List<ExerciseHistoryPoint> _history = [];

  _ChartMode _chartMode = _ChartMode.estimated1RM;

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
        _api.getLastSets(widget.exercise.id),
        _api.getExerciseWorkoutHistory(widget.exercise.id),
      ]);
      if (!mounted) return;
      setState(() {
        _lastSets = results[0] as ExerciseLastSets?;
        _history  = results[1] as List<ExerciseHistoryPoint>;
        _loading  = false;
      });
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
        backgroundColor: AppColors.primary,
        title: Text(
          widget.exercise.name,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: 'Todos os records',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PRBoardPage()),
            ),
          ),
        ],
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

    if (_history.isEmpty && _lastSets == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_rounded, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Nenhum dado ainda',
                style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete seu primeiro treino com este exercício para ver o progresso.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PR Card
          if (_history.isNotEmpty) ...[
            _buildPRCard(),
            const SizedBox(height: 16),
          ],

          // Chart
          if (_history.length >= 2) ...[
            _buildChartCard(),
            const SizedBox(height: 16),
          ],

          // Last workout
          if (_lastSets != null && _lastSets!.hasData) ...[
            _buildLastWorkoutCard(),
            const SizedBox(height: 16),
          ],

          // Session history table
          if (_history.isNotEmpty) _buildHistoryTable(),
        ],
      ),
    );
  }

  // ── PR Card ────────────────────────────────────────────────────────────────

  Widget _buildPRCard() {
    final maxWeight = _history.map((h) => h.maxWeight).reduce((a, b) => a > b ? a : b);
    final maxVolume = _history.map((h) => h.volume).reduce((a, b) => a > b ? a : b);
    final max1RM    = _history.map((h) => h.estimated1RM).reduce((a, b) => a > b ? a : b);

    String fmtKg(double v) => v == v.roundToDouble()
        ? '${v.toInt()} kg'
        : '${v.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Records Pessoais',
                style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _prStat('Maior Peso', fmtKg(maxWeight)),
              _prStat('1RM estimado', fmtKg(max1RM)),
              _prStat('Maior Volume', '${maxVolume.toInt()} kg'),
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
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Chart Card ─────────────────────────────────────────────────────────────

  Widget _buildChartCard() {
    final points = _history;

    final spots = List.generate(
      points.length,
      (i) => FlSpot(
        i.toDouble(),
        _chartMode == _ChartMode.weight
            ? points[i].maxWeight
            : points[i].estimated1RM,
      ),
    );

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).clamp(5.0, double.infinity) * 0.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _chartMode == _ChartMode.weight ? 'Evolução de Carga' : 'Evolução e1RM',
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _chartToggle(_ChartMode.estimated1RM, 'e1RM'),
              const SizedBox(width: 6),
              _chartToggle(_ChartMode.weight, 'Carga'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY + padding * 2) / 4).clamp(1, 100),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (points.length / 4).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final date = points[idx].date;
                        final parts = date.split('-');
                        if (parts.length < 3) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${parts[2]}/${parts[1]}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primary,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.12),
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

  Widget _chartToggle(_ChartMode mode, String label) {
    final selected = _chartMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Last Workout Card ──────────────────────────────────────────────────────

  Widget _buildLastWorkoutCard() {
    final ls = _lastSets!;

    String fmtKg(double v) => v == v.roundToDouble()
        ? '${v.toInt()} kg'
        : '${v.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                ls.workoutDate != null
                    ? 'Último treino · ${ls.workoutDate}'
                    : 'Último treino',
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ls.sets.map((s) {
              final w = (s['weight'] as num?)?.toDouble() ?? 0.0;
              final r = (s['reps'] as num?)?.toInt() ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${fmtKg(w)} × $r',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              );
            }).toList(),
          ),
          if (ls.maxWeight != null || ls.volume != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (ls.maxWeight != null) ...[
                  _statChip(
                    Icons.fitness_center_rounded,
                    'Máx peso',
                    fmtKg(ls.maxWeight!),
                  ),
                  const SizedBox(width: 12),
                ],
                if (ls.volume != null) ...[
                  _statChip(
                    Icons.show_chart_rounded,
                    'Volume',
                    '${ls.volume!.toInt()} kg',
                  ),
                  const SizedBox(width: 12),
                ],
                if (ls.estimated1RM != null)
                  _statChip(
                    Icons.bolt_rounded,
                    '1RM est.',
                    fmtKg(ls.estimated1RM!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }

  // ── History Table ──────────────────────────────────────────────────────────

  Widget _buildHistoryTable() {
    String fmtKg(double v) => v == v.roundToDouble()
        ? '${v.toInt()} kg'
        : '${v.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histórico de sessões',
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Header row
          Row(
            children: [
              Expanded(flex: 3, child: Text('Data', style: _headerStyle)),
              Expanded(flex: 2, child: Text('Carga máx', style: _headerStyle, textAlign: TextAlign.end)),
              Expanded(flex: 2, child: Text('Volume', style: _headerStyle, textAlign: TextAlign.end)),
              Expanded(flex: 2, child: Text('1RM est.', style: _headerStyle, textAlign: TextAlign.end)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // Data rows — show newest first (reverse iteration)
          ...List.generate(_history.length, (i) {
            final h = _history[_history.length - 1 - i];
            final parts = h.date.split('-');
            final dateLabel = parts.length >= 3
                ? '${parts[2]}/${parts[1]}/${parts[0].substring(2)}'
                : h.date;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(dateLabel,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(fmtKg(h.maxWeight),
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${h.volume.toInt()} kg',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(fmtKg(h.estimated1RM),
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
