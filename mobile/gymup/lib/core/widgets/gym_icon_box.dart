import 'package:flutter/material.dart';

enum GymIconSize { sm, md, lg }
//                 32   44   50    ← tamanhos em pixels

class GymIconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;
  final GymIconSize size;
  final double? borderRadius;

  const GymIconBox({
    super.key,
    required this.icon,
    required this.bg,
    required this.color,
    this.size = GymIconSize.md,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final (boxSize, iconSize, defaultRadius) = switch (size) {
      GymIconSize.sm => (32.0, 18.0, 10.0),
      GymIconSize.md => (44.0, 22.0, 13.0),
      GymIconSize.lg => (50.0, 24.0, 14.0),
    };

    return Container(
      width: boxSize, height: boxSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius ?? defaultRadius),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
