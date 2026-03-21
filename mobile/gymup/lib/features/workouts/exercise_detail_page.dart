import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'models/workout_model.dart';
import 'widgets/exercise_image_widget.dart';
import 'workout_api_service.dart';

// ── Brand tokens (azul do app, consistente com workout_step_page) ─────────────
const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kBlueBg   = Color(0xFFEFF6FF);   // fundo suave azul
const _kRedBg    = Color(0xFFFEF2F2);   // fundo erros
const _kRed      = Color(0xFFEF4444);
const _kGreenBg  = Color(0xFFF0FDF4);   // fundo dicas
const _kGreen    = Color(0xFF10B981);
const _kDark     = Color(0xFF0F172A);   // texto principal
const _kMid      = Color(0xFF475569);   // texto secundário
const _kGrey     = Color(0xFFF1F5F9);   // chip neutro

class ExerciseDetailPage extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  ExerciseLastSets? _lastSets;
  bool _loadingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (widget.exercise.id <= 0) return;
    setState(() => _loadingProgress = true);
    try {
      final lastSets = await WorkoutApiService().getLastSets(widget.exercise.id);
      if (!mounted) return;
      setState(() {
        _lastSets = lastSets;
        _loadingProgress = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar: gradiente azul consistente com o step page ─────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // ── FAB: ação primária no thumb zone ──────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.fitness_center_rounded, size: 20),
        label: const Text(
          'Voltar ao treino',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _loadingProgress
            ? const _ExerciseDetailSkeleton()
            : _buildContent(exercise),
      ),
    );
  }

  // ── Conteúdo principal ────────────────────────────────────────────────────

  Widget _buildContent(ExerciseModel exercise) {
    return ListView(
      key: const ValueKey('content'),
      padding: EdgeInsets.zero,
      children: [

        // ── 1. GIF Hero — full-width, fundo branco, sombra ───────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ExerciseGifPanel(
            exercise: exercise,
            height: 280,
            borderRadius: BorderRadius.zero,
          ),
        ),

        // ── 2. Nome + grupo muscular ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  height: 1.2,
                ),
              ),
              if (exercise.muscleGroup.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(label: exercise.muscleGroup, isPrimary: true),
                    if (exercise.primaryMuscle != null &&
                        exercise.primaryMuscle!.toLowerCase() !=
                            exercise.muscleGroup.toLowerCase())
                      _Chip(label: exercise.primaryMuscle!, isPrimary: true),
                    for (final m in exercise.secondaryMuscles)
                      _Chip(label: m, isPrimary: false),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── 3. Card de progresso (aparece quando há dados) ───────────────
        _buildProgressCard(),

        // ── 4. Sobre o exercício ──────────────────────────────────────────
        if (exercise.description != null &&
            exercise.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Sobre o exercício'),
                const SizedBox(height: 12),
                Text(
                  exercise.description!.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kMid,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── 5. Como executar ─────────────────────────────────────────────
        if (exercise.executionSteps.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Como executar',
                  icon: Icons.format_list_numbered_rounded,
                ),
                const SizedBox(height: 14),
                ...exercise.executionSteps.asMap().entries.map(
                  (e) => _StepRow(index: e.key, text: e.value),
                ),
              ],
            ),
          ),
        ],

        // ── 6. Erros comuns ───────────────────────────────────────────────
        if (exercise.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Erros comuns',
                  icon: Icons.warning_amber_rounded,
                  iconColor: _kRed,
                  accentColor: _kRed,
                ),
                const SizedBox(height: 14),
                ...exercise.commonMistakes.map((m) => _MistakeRow(text: m)),
              ],
            ),
          ),
        ],

        // ── 7. Dicas ─────────────────────────────────────────────────────
        if (exercise.tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Dicas',
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: _kGreen,
                  accentColor: _kGreen,
                ),
                const SizedBox(height: 14),
                ...exercise.tips.map((t) => _TipRow(text: t)),
              ],
            ),
          ),
        ],

        // ── Empty state ───────────────────────────────────────────────────
        if (!exercise.hasEducationalContent &&
            _lastSets == null &&
            !_loadingProgress)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 30,
                    color: _kBlue,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Instruções não disponíveis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'O personal ainda não cadastrou as instruções deste exercício.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kMid,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // Espaço para o FAB não cobrir o último item
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Card de progresso ─────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    final ls = _lastSets;
    if (ls == null || !ls.hasData) return const SizedBox.shrink();

    String fmtKg(double v) =>
        v == v.roundToDouble() ? '${v.toInt()} kg' : '${v.toStringAsFixed(1)} kg';

    final maxW = ls.maxWeight;
    final e1rm = ls.estimated1RM;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), _kBlue],
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 15, color: Color(0xFFFFD700)),
                const SizedBox(width: 6),
                const Text(
                  'Seu progresso',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                if (ls.workoutDate != null) ...[
                  const Spacer(),
                  Text(
                    ls.workoutDate!,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (maxW != null)
                  Expanded(
                    child: _ProgressStat(
                      label: 'Recorde',
                      value: fmtKg(maxW),
                      icon: Icons.military_tech_rounded,
                      iconColor: const Color(0xFFFFD700),
                    ),
                  ),
                if (e1rm != null && e1rm > 0) ...[
                  Container(width: 1, height: 40, color: Colors.white12),
                  Expanded(
                    child: _ProgressStat(
                      label: 'e1RM',
                      value: fmtKg(e1rm),
                      icon: Icons.speed_rounded,
                      iconColor: const Color(0xFF34D399),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ExerciseDetailSkeleton extends StatelessWidget {
  const _ExerciseDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // GIF placeholder
          Container(height: 280, color: Colors.white),

          const SizedBox(height: 20),

          // Title block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 26),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ShimmerBox(width: 80, height: 26, radius: 20),
                    const SizedBox(width: 8),
                    _ShimmerBox(width: 60, height: 26, radius: 20),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShimmerBox(width: double.infinity, height: 90, radius: 16),
          ),

          const SizedBox(height: 20),

          // Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShimmerBox(width: double.infinity, height: 120, radius: 16),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShimmerBox(width: double.infinity, height: 200, radius: 16),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Card container ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Cabeçalho de seção com barra lateral azul ─────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Color? accentColor;

  const _SectionHeader({
    required this.title,
    this.icon,
    this.iconColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? _kBlue;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 16, color: iconColor ?? _kBlue),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
      ],
    );
  }
}

// ── Linha de passo numerado ───────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final int index;
  final String text;

  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _kBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kMid,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Linha de erro ─────────────────────────────────────────────────────────────

class _MistakeRow extends StatelessWidget {
  final String text;

  const _MistakeRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _kRedBg,
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: BorderSide(color: _kRed, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.close_rounded, size: 14, color: _kRed),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7F1D1D),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linha de dica ─────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _kGreenBg,
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: BorderSide(color: _kGreen, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check_rounded, size: 14, color: _kGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF064E3B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de grupo muscular ────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _Chip({required this.label, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? _kBlueBg : _kGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? _kBlue.withValues(alpha: 0.35)
              : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPrimary ? _kBlue : _kMid,
        ),
      ),
    );
  }
}

// ── Stat de progresso ─────────────────────────────────────────────────────────

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
