import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../workouts/workout_api_service.dart';

// ─── Pintor do anel de progresso ─────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center     = Offset(size.width / 2, size.height / 2);
    final radius     = (size.width / 2) - 4;
    const strokeW    = 5.5;

    final glowPaint = Paint()
      ..color      = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = strokeW + 3
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..maskFilter  = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);

    final trackPaint = Paint()
      ..color      = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = strokeW
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final arcPaint = Paint()
      ..color      = Colors.white
      ..strokeWidth = strokeW
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Card semanal principal ───────────────────────────────────────────────────

class HomeWeeklyCard extends StatelessWidget {
  final int workoutsDone;
  final int weeklyGoal;
  final List<WeeklyProgressDay> weeklyProgress;
  final bool isRestDayToday;
  final VoidCallback? onStartTap;

  const HomeWeeklyCard({
    super.key,
    required this.workoutsDone,
    required this.weeklyGoal,
    required this.weeklyProgress,
    this.isRestDayToday = false,
    this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final goal     = weeklyGoal > 0 ? weeklyGoal : 1;
    final ratio    = (workoutsDone / goal).clamp(0.0, 1.0);
    final goalMet  = workoutsDone >= weeklyGoal;
    final remaining = goalMet ? 0 : weeklyGoal - workoutsDone;
    final weekNum  = _currentWeekNumber();

    return Container(
      width: 350,
      height: 288.19,
      decoration: BoxDecoration(
        gradient: AppColors.gradientWeekCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.weekCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
          // Blob decorativo (canto superior direito)
          Positioned(
            top: -40,
            right: -40,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [Color(0x7FC8F84A), Color(0x00C8F84A)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: label + anel
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'SEMANA $weekNum · SUA META',
                          style: AppText.pjs(
                            size: 10, weight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.78),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Anel de progresso 56×56
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(56, 56),
                            painter: _RingPainter(progress: ratio),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(ratio * 100).round()}',
                                style: AppText.sg(
                                  size: 14, weight: FontWeight.w700,
                                  color: Colors.white, letterSpacing: -0.3,
                                  height: 1,
                                ),
                              ),
                              Opacity(
                                opacity: 0.85,
                                child: Text(
                                  '%',
                                  style: AppText.sg(
                                    size: 9, weight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3, height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Contador grande: "4 /5"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$workoutsDone',
                      style: AppText.sg(
                        size: 56, weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -2.5, height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Opacity(
                      opacity: 0.60,
                      child: Text(
                        '/$weeklyGoal',
                        style: AppText.sg(
                          size: 27.8, weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1, height: 0.96,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  'treinos concluídos esta semana',
                  style: AppText.pjs(
                    size: 14, weight: FontWeight.w600,
                    color: Colors.white, letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 18),

                // Barras dos 7 dias
                _WeekDayBars(days: weeklyProgress),

                const SizedBox(height: 14),

                // CTA inferior
                _CtaBanner(
                  goalMet:        goalMet,
                  remaining:      remaining,
                  isRestDayToday: isRestDayToday,
                  onTap:          onStartTap,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  static int _currentWeekNumber() {
    final now  = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final days = now.difference(jan1).inDays;
    return ((days + jan1.weekday - 1) ~/ 7) + 1;
  }
}

// ─── Barras dos dias ──────────────────────────────────────────────────────────

class _WeekDayBars extends StatelessWidget {
  final List<WeeklyProgressDay> days;

  const _WeekDayBars({required this.days});

  /// Labels Seg→Dom
  static const _labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    // Dart weekday: 1=Mon→7=Sun. Converter para índice 0=Mon→6=Sun.
    final todayIdx = DateTime.now().weekday - 1;

    // API dayOfWeek: 0=Dom, 1=Seg, …, 6=Sáb → índice Mon-first: 0=Mon→6=Sun
    // API 0=Sun → idx 6, API 1=Mon → idx 0, API 2=Tue → idx 1 …
    final trainedMap = <int, bool>{};
    for (final d in days) {
      final idx = d.dayOfWeek == 0 ? 6 : d.dayOfWeek - 1;
      trainedMap[idx] = d.trained;
    }

    return Row(
      children: List.generate(7, (i) {
        final trained  = trainedMap[i] ?? false;
        final isToday  = i == todayIdx;
        final isFuture = i > todayIdx;

        Color barColor;
        double labelOpacity;

        if (trained) {
          barColor     = AppColors.lime;
          labelOpacity = 0.55;
        } else if (isToday) {
          barColor     = Colors.white.withValues(alpha: 0.85);
          labelOpacity = 0.95;
        } else if (isFuture) {
          barColor     = Colors.white.withValues(alpha: 0.22);
          labelOpacity = 0.55;
        } else {
          barColor     = Colors.white.withValues(alpha: 0.22);
          labelOpacity = 0.55;
        }

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 5),
              Opacity(
                opacity: labelOpacity,
                child: Text(
                  _labels[i],
                  style: AppText.pjs(
                    size: 9.5, weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Banner CTA inferior ──────────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  final bool goalMet;
  final int remaining;
  final bool isRestDayToday;
  final VoidCallback? onTap;

  const _CtaBanner({
    required this.goalMet,
    required this.remaining,
    required this.isRestDayToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 15,
                  color: Color(0xFF1F4FC4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: goalMet
                  ? Text(
                      'Meta da semana concluída! 🎉',
                      style: AppText.pjs(
                        size: 12.5, weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        style: AppText.pjs(
                          size: 12.5, weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'Falta '),
                          TextSpan(
                            text: '$remaining treino${remaining == 1 ? '' : 's'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' para bater sua meta'),
                        ],
                      ),
                    ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRestDayToday ? 'Treinar' : goalMet ? 'Ver' : 'Começar',
                  style: AppText.pjs(
                    size: 12, weight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
