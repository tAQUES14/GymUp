import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum GymBadgeVariant { dark, orange, lime, blue }

class GymBadge extends StatelessWidget {
  final String label;
  final GymBadgeVariant variant;

  const GymBadge(this.label, {super.key, this.variant = GymBadgeVariant.dark});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      GymBadgeVariant.dark   => (AppColors.ink,        AppColors.lime),
      GymBadgeVariant.orange => (AppColors.orangeTint,  AppColors.orangeDark),
      GymBadgeVariant.lime   => (AppColors.lime,        AppColors.blueDark),
      GymBadgeVariant.blue   => (AppColors.blueTint,    AppColors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: AppText.badge.copyWith(color: fg)),
    );
  }
}
