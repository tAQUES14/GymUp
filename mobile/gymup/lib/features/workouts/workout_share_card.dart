import 'package:flutter/material.dart';

const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kCyan = Color(0xFF36B7D8);

/// Static 4:5 card optimised for screenshot capture.
/// All data is passed in; no async calls or interactivity.
class WorkoutShareCard extends StatelessWidget {
  final String userName;
  final String gymName;
  final int pontosGerados;
  final int streak;
  final int duracaoMinutos;
  final int setsConcluidos;
  final bool completed;

  const WorkoutShareCard({
    super.key,
    required this.userName,
    required this.gymName,
    required this.pontosGerados,
    required this.streak,
    required this.duracaoMinutos,
    required this.setsConcluidos,
    this.completed = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = completed ? 'Treino concluído' : 'Treino encerrado';
    final subtitle = completed ? 'feito no GymUp' : 'sem conclusão';
    final icon = completed ? Icons.emoji_events_rounded : Icons.close_rounded;
    final iconColor = completed ? const Color(0xFFE5A300) : const Color(0xFFE5484D);
    final iconBg = completed ? const Color(0xFFFFF8E1) : const Color(0xFFFFE3E3);
    final iconBorder = completed ? const Color(0xFFFFD56B) : const Color(0xFFFFB3B3);
    final metricLabel = completed ? 'Séries' : 'Concluídos';

    return SizedBox(
      width: 320,
      height: 400,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBlueDark, _kBlue, _kCyan],
          ),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Gym',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Up',
                                style: TextStyle(
                                  color: Color(0xFFC8F84A),
                                  fontSize: 21,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                            ),
                            child: Text(
                              gymName.isNotEmpty ? gymName : 'GymUp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: iconBorder),
                      ),
                      child: Icon(icon, color: iconColor, size: 32),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName.isNotEmpty ? userName : 'Atleta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _MetricTile(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFD56B),
                          value: '+$pontosGerados',
                          label: 'Pontos',
                        ),
                        const SizedBox(width: 10),
                        _MetricTile(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF8A3D),
                          value: '$streak',
                          label: 'Streak',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetricTile(
                          icon: Icons.timer_outlined,
                          iconColor: const Color(0xFFC8F84A),
                          value: '${duracaoMinutos}min',
                          label: 'Duração',
                        ),
                        const SizedBox(width: 10),
                        _MetricTile(
                          icon: Icons.fitness_center_rounded,
                          iconColor: Colors.white,
                          value: '$setsConcluidos',
                          label: metricLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Gym',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 11,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: 'Up',
                                style: TextStyle(
                                  color: const Color(0xFFC8F84A).withValues(alpha: 0.86),
                                  fontSize: 11,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 11,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 10.5,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
