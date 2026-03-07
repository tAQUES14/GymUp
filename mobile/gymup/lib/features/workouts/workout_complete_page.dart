import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WorkoutCompletePage extends StatefulWidget {
  final String workoutNome;
  final int duracaoMinutos;
  final int setsConcluidos;
  final int setsTotais;
  final int streak;
  final int pontosGerados;
  final int totalPontos;
  final String? noPointsReason;

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
  });

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.noPointsReason != null
          ? const Color(0xFF455A64)
          : AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Troféu animado — exibido apenas quando o treino foi validado
              if (widget.noPointsReason == null) ...[
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

              // Título e subtítulo
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      widget.noPointsReason != null
                          ? 'Treino não validado'
                          : 'Treino validado!',
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
                    horizontal: 20,
                    vertical: 22,
                  ),
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
                        icon: Icons.fitness_center,
                        value: '${widget.setsConcluidos}/${widget.setsTotais}',
                        label: 'Sets',
                      ),
                      _vDivider(),
                      _statBlock(
                        icon: Icons.local_fire_department,
                        value: '${widget.streak}',
                        label: 'Streak 🔥',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Aviso quando pontos não foram contados
              if (widget.pontosGerados == 0 && widget.noPointsReason != null)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 20,
                        ),
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

              // Pontos gerados (do backend)
              if (widget.pontosGerados > 0)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
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
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 30,
                        ),
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

              // Total de pontos
              if (widget.totalPontos > 0)
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

              // Botão voltar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    );
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

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 52,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}
