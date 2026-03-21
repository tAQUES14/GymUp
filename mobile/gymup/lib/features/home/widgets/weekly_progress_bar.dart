import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

const _kBlue = Color(0xFF2563EB);

class WeeklyProgressBar extends StatelessWidget {
  final List<bool> weeklyProgress;

  const WeeklyProgressBar({
    super.key,
    this.weeklyProgress = const [false, false, false, false, false, false, false],
  });

  @override
  Widget build(BuildContext context) {
    // Detecta o dia atual (1=seg, 7=dom → índice 0–6)
    final weekdayIndex = DateTime.now().weekday - 1;

    final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Esta semana',
              style: AppTypography.h3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${weeklyProgress.where((d) => d).length}/7 dias',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done    = i < weeklyProgress.length && weeklyProgress[i];
              final isToday = i == weekdayIndex;

              Color circleBg;
              Color borderColor;
              Widget? circleChild;

              if (done) {
                circleBg    = _kBlue;
                borderColor = _kBlue;
                circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
              } else if (isToday) {
                circleBg    = Colors.white;
                borderColor = _kBlue;
                circleChild = Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                );
              } else {
                circleBg    = const Color(0xFFF3F4F6);
                borderColor = Colors.transparent;
                circleChild = null;
              }

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Center(child: circleChild),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: AppTypography.caption.copyWith(
                      fontWeight: isToday || done ? FontWeight.w700 : FontWeight.normal,
                      color: done
                          ? _kBlue
                          : isToday
                              ? _kBlue
                              : AppColors.textSecondary,
                      fontSize: 10,
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
