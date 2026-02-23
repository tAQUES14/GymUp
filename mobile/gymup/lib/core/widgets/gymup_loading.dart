import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GymUpLoading extends StatelessWidget {
  const GymUpLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
