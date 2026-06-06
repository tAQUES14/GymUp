import 'package:flutter/material.dart';
import 'gym_card.dart';
import 'gym_icon_box.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GymListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const GymListTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          GymIconBox(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.itemTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.subtitle),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
