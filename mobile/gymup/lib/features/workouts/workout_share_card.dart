import 'package:flutter/material.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

/// Static 4:5 card optimised for screenshot capture via ScreenshotController.
/// All data is passed in; no async calls or interactivity.
class WorkoutShareCard extends StatelessWidget {
  final String userName;
  final String gymName;
  final int pontosGerados;
  final int streak;
  final int duracaoMinutos;
  final int setsConcluidos;

  const WorkoutShareCard({
    super.key,
    required this.userName,
    required this.gymName,
    required this.pontosGerados,
    required this.streak,
    required this.duracaoMinutos,
    required this.setsConcluidos,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 450,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), _kBlueDark],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlue.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlueDark.withValues(alpha: 0.20),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: branding + gym
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo text
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Gym',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Up',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gym name badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(
                          gymName.isNotEmpty ? gymName : 'GymUp',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Trophy + user name
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 52,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Treino concluído!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName.isNotEmpty ? userName : 'Atleta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Metrics 2×2 grid
                  Row(
                    children: [
                      _MetricTile(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        value: '+$pontosGerados',
                        label: 'Pontos',
                      ),
                      const SizedBox(width: 12),
                      _MetricTile(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFB923C),
                        value: '$streak',
                        label: 'Streak',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MetricTile(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF34D399),
                        value: '${duracaoMinutos}min',
                        label: 'Duração',
                      ),
                      const SizedBox(width: 12),
                      _MetricTile(
                        icon: Icons.fitness_center_rounded,
                        iconColor: const Color(0xFF60A5FA),
                        value: '$setsConcluidos',
                        label: 'Séries',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Footer
                  Text(
                    'gymup.app',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
