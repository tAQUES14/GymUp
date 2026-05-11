import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workouts/workout_api_service.dart';

const _kBlue = Color(0xFF2563EB);
const _kGray = Color(0xFFF3F4F6);

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

    final trainedCount = weeklyProgress.where((d) => d.trained).length;
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
            Text(
              'Esta semana',
              style: AppTypography.h3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              planDaysCount > 0
                  ? '$trainedCount/$planDaysCount treino${planDaysCount == 1 ? '' : 's'}'
                  : '$trainedCount treino${trainedCount == 1 ? '' : 's'}',
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
              final dow        = displayOrder[i];
              final day        = byDow[dow];
              final isToday    = dow == todayDow;
              final trained    = day?.trained ?? false;
              final isObligatory = day?.isObligatory ?? false;
              final isRestDay  = day?.isRestDay ?? true;
              final isPast     = _isDayPast(dow, now);

              Color   circleBg;
              Color   borderColor;
              Widget? circleChild;

              if (trained) {
                // Treinou: azul sólido com check
                circleBg    = _kBlue;
                borderColor = _kBlue;
                circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
              } else if (isObligatory && isPast && !isToday) {
                // Obrigatório perdido: vermelho com ×
                circleBg    = Colors.red.shade50;
                borderColor = Colors.red.shade300;
                circleChild = Icon(Icons.close_rounded, color: Colors.red.shade400, size: 16);
              } else if (isToday) {
                // Hoje: borda azul com ponto
                circleBg    = Colors.white;
                borderColor = _kBlue;
                circleChild = Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                );
              } else if (isRestDay) {
                // Descanso: cinza muito claro com lua
                circleBg    = Colors.grey.shade100;
                borderColor = Colors.grey.shade200;
                circleChild = Icon(Icons.bedtime_rounded, color: Colors.grey.shade400, size: 14);
              } else {
                // Futuro treino planejado: cinza neutro
                circleBg    = _kGray;
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
                      fontWeight: (isToday || trained) ? FontWeight.w700 : FontWeight.normal,
                      color: trained
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

  /// Retorna true se o dia já passou nesta semana (usando a ordem Seg→Dom).
  bool _isDayPast(int dow, DateTime now) {
    const displayOrder = [1, 2, 3, 4, 5, 6, 0];
    final todayDow   = now.weekday % 7;
    if (dow == todayDow) return false;
    final dowIndex   = displayOrder.indexOf(dow);
    final todayIndex = displayOrder.indexOf(todayDow);
    return dowIndex < todayIndex;
  }
}
