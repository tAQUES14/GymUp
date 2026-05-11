import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'workout_share_card.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class WorkoutCompletePage extends StatefulWidget {
  final String workoutNome;
  final int duracaoMinutos;
  final int setsConcluidos;
  final int setsTotais;
  final int streak;
  final int pontosGerados;
  final int totalPontos;
  final String? noPointsReason;

  /// Motivational progress message from the backend, e.g. "+2kg no Supino".
  final String? progressMessage;

  /// PR achievement messages from this session, e.g. "🔥 Novo recorde de carga".
  final List<String> prMessages;

  /// Total workout volume (sum of weight × reps) in kg.
  final int workoutVolume;

  const WorkoutCompletePage({
    super.key,
    required this.workoutNome,
    required this.duracaoMinutos,
    required this.setsConcluidos,
    required this.setsTotais,
    required this.streak,
    required this.pontosGerados,
    required this.totalPontos,
    this.noPointsReason,
    this.progressMessage,
    this.prMessages = const [],
    this.workoutVolume = 0,
  });

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final GlobalKey _repaintKey = GlobalKey();
  String _userName = '';
  String _gymName  = '';
  bool _shareLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );
    _controller.forward();

    _loadCachedUserData();
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _gymName  = prefs.getString('gym_name')  ?? '';
    });
  }

  Future<void> _shareCard() async {
    setState(() => _shareLoading = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !mounted) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !mounted) return;
      final Uint8List imageBytes = byteData.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      final file =
          await File('${tempDir.path}/gymup_workout.png').writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Treino concluído no GymUp! 💪',
      );
    } finally {
      if (mounted) setState(() => _shareLoading = false);
    }
  }

  void _showShareBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareBottomSheet(
        repaintKey: _repaintKey,
        shareCard: WorkoutShareCard(
          userName:        _userName,
          gymName:         _gymName,
          pontosGerados:   widget.pontosGerados,
          streak:          widget.streak,
          duracaoMinutos:  widget.duracaoMinutos,
          setsConcluidos:  widget.setsConcluidos,
        ),
        onShare: _shareCard,
        isLoading: _shareLoading,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPoints = widget.noPointsReason == null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasPoints
                ? const [Color(0xFF1E3A8A), _kBlueDark, _kBlue]
                : const [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Trophy — only when validated
                if (hasPoints) ...[
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 108,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Title + subtitle
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        hasPoints ? 'Treino validado!' : 'Treino não validado',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.workoutNome,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Stats card
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statBlock(
                          icon: Icons.timer_outlined,
                          value: '${widget.duracaoMinutos}min',
                          label: 'Duração',
                        ),
                        _vDivider(),
                        _statBlock(
                          icon: Icons.fitness_center_rounded,
                          value: '${widget.setsConcluidos}/${widget.setsTotais}',
                          label: 'Sets',
                        ),
                        _vDivider(),
                        _statBlock(
                          icon: Icons.local_fire_department_rounded,
                          value: '${widget.streak}',
                          label: 'Streak 🔥',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Workout volume
                if (widget.workoutVolume > 0)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fitness_center_rounded,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Volume total: ${widget.workoutVolume} kg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // PR messages
                if (widget.prMessages.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: widget.prMessages.map((msg) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.40),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events_rounded,
                                    color: Color(0xFFFFD700), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    msg,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 6),

                // Progress message (personal record / improvement)
                if (widget.progressMessage != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.progressMessage!,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 6),

                // No-points reason
                if (widget.pontosGerados == 0 && widget.noPointsReason != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.noPointsReason!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Points earned
                if (widget.pontosGerados > 0)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 30),
                          const SizedBox(width: 10),
                          Text(
                            '+${widget.pontosGerados} pontos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Total points — only shown when this session actually earned points
                if (widget.pontosGerados > 0 && widget.totalPontos > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Total: ${widget.totalPontos} pontos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const Spacer(flex: 3),

                // Share button — only when points were earned
                if (widget.pontosGerados > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _showShareBottomSheet,
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text(
                          'Compartilhar treino',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (_) => false);
                    },
                    child: const Text(
                      'Voltar ao início',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBlock({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 52,
        color: Colors.white.withValues(alpha: 0.25),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ShareBottomSheet extends StatefulWidget {
  final GlobalKey repaintKey;
  final WorkoutShareCard shareCard;
  final VoidCallback onShare;
  final bool isLoading;

  const _ShareBottomSheet({
    required this.repaintKey,
    required this.shareCard,
    required this.onShare,
    required this.isLoading,
  });

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  bool _sharing = false;

  Future<void> _handleShare() async {
    setState(() => _sharing = true);
    widget.onShare();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Compartilhar treino',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 20),

          // Card preview wrapped for capture
          RepaintBoundary(
            key: widget.repaintKey,
            child: widget.shareCard,
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Agora não',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _sharing ? null : _handleShare,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    _sharing ? 'Preparando...' : 'Compartilhar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
