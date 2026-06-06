import 'package:flutter/material.dart';
import 'gym_card.dart';
import 'gym_icon_box.dart';
import '../theme/app_text_styles.dart';

class GymStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const GymStatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GymIconBox(icon: icon, bg: iconBg, color: iconColor, size: GymIconSize.sm),
              Text(label, style: AppText.cardLabel),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppText.statValue),
          const SizedBox(height: 4),
          Text(sub, style: AppText.subtitle),
        ],
      ),
    );
  }
}
