import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GymProgressBar extends StatelessWidget {
  final double value;       // 0.0 a 1.0
  final bool showLabel;
  final Color? color;
  final Color? bgColor;
  final double height;

  const GymProgressBar({
    super.key,
    required this.value,
    this.showLabel = true,
    this.color,
    this.bgColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.blue;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: height,
              backgroundColor: bgColor ?? fg.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: AppText.metricSmall.copyWith(color: fg),
          ),
        ],
      ],
    );
  }
}
