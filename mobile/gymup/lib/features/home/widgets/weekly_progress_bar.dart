import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gym_card.dart';
import '../../workouts/workout_api_service.dart';

/// Barra de progresso semanal baseada no calendário do plano.
///
/// Exibe Segunda → Domingo com os seguintes estados:
///   ✔ azul sólido  — treinou (qualquer treino com pontos)
///   ❌ vermelho     — dia obrigatório perdido (passado, não treinado)
///   🔵 hoje         — borda azul com ponto central
///   🌙 cinza claro  — dia de descanso do plano
///   ⚪ cinza         — dia de treino futuro (ainda não chegou)
class WeeklyProgressBar extends StatelessWidget {
  final List<WeeklyProgressDay> weeklyProgress;

  const WeeklyProgressBar({
    super.key,
    this.weeklyProgress = const [],
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, WeeklyProgressDay> byDow = {
      for (final d in weeklyProgress) d.dayOfWeek: d,
    };

    final now      = DateTime.now();
    final todayDow = now.weekday % 7; // Dart: 1=Mon..7=Sun → 0=Sun..6=Sat

    final trainedCount  = weeklyProgress.where((d) => d.trained).length;
    final planDaysCount = weeklyProgress.where((d) => d.isObligatory).length;

    // Segunda → Domingo (1, 2, 3, 4, 5, 6, 0)
    const displayOrder = [1, 2, 3, 4, 5, 6, 0];
    const labels       = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Esta semana', style: AppText.sectionTitle),
            Text(
              planDaysCount > 0
                  ? '$trainedCount/$planDaysCount treino${planDaysCount == 1 ? '' : 's'}'
                  : '$trainedCount treino${trainedCount == 1 ? '' : 's'}',
              style: AppText.pjs(
                size: 12, weight: FontWeight.w600, color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GymCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dow          = displayOrder[i];
              final day          = byDow[dow];
              final isToday      = dow == todayDow;
              final trained      = day?.trained ?? false;
              final isObligatory = day?.isObligatory ?? false;
              final isRestDay    = day?.isRestDay ?? true;
              final isPast       = _isDayPast(dow, now);

              Color   circleBg;
              Color   borderColor;
              Widget? circleChild;

              if (trained) {
                circleBg    = AppColors.blue;
                borderColor = AppColors.blue;
                circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
              } else if (isObligatory && isPast && !isToday) {
                circleBg    = Colors.red.shade50;
                borderColor = Colors.red.shade300;
                circleChild = Icon(Icons.close_rounded, color: Colors.red.shade400, size: 16);
              } else if (isToday) {
                circleBg    = Colors.white;
                borderColor = AppColors.blue;
                circleChild = Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.blue, shape: BoxShape.circle,
                  ),
                );
              } else if (isRestDay) {
                circleBg    = Colors.grey.shade100;
                borderColor = Colors.grey.shade200;
                circleChild = Icon(Icons.bedtime_rounded, color: Colors.grey.shade400, size: 14);
              } else {
                circleBg    = AppColors.background;
                borderColor = Colors.transparent;
                circleChild = null;
              }

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36, height: 36,
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
                    style: AppText.pjs(
                      size: 10,
                      weight: (isToday || trained) ? FontWeight.w700 : FontWeight.w500,
                      color: (trained || isToday) ? AppColors.blue : AppColors.inkMuted,
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

  bool _isDayPast(int dow, DateTime now) {
    const displayOrder = [1, 2, 3, 4, 5, 6, 0];
    final todayDow   = now.weekday % 7;
    if (dow == todayDow) return false;
    final dowIndex   = displayOrder.indexOf(dow);
    final todayIndex = displayOrder.indexOf(todayDow);
    return dowIndex < todayIndex;
  }
}
