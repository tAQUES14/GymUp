import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gymup_card.dart';

class WeeklyProgressBar extends StatelessWidget {
  final List<int> diasTreinados;

  const WeeklyProgressBar({super.key, this.diasTreinados = const []});

  @override
  Widget build(BuildContext context) {
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu progresso nesta semana', style: AppTypography.h3),
        const SizedBox(height: 16),
        GymUpCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNumber = index + 1; // 1 = Seconda ... 7 = Domingo
              final isChecked = diasTreinados.contains(dayNumber);

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? AppColors.primary
                          : AppColors.background,
                      shape: BoxShape.circle,
                      border: isChecked
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: AppTypography.caption.copyWith(
                      fontWeight: isChecked
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isChecked
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
