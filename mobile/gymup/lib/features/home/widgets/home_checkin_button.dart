import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';

/// Botão grande de check-in — gradiente azul escuro, ícone QR, badge de pontos.
class HomeCheckinButton extends StatelessWidget {
  final bool hasCheckedIn;
  final VoidCallback? onTap;

  const HomeCheckinButton({
    super.key,
    required this.hasCheckedIn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.19, -0.77),
            end: Alignment(0.81, 1.77),
            colors: [
              AppColors.blueDark,
              AppColors.blue,
              AppColors.blueLight,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.buttonBlue,
        ),
        child: Row(
              children: [
                // Ícone QR
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: const Color(0x2EFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0x40FFFFFF),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCheckedIn ? 'Check-in realizado' : 'Fazer check-in',
                        style: AppText.pjs(
                          size: 17, weight: FontWeight.w700,
                          color: Colors.white, letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCheckedIn
                            ? 'Você já fez check-in hoje!'
                            : 'Escaneie o QR na recepção',
                        style: AppText.pjs(
                          size: 12.5, weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de pontos
                if (!hasCheckedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Liberar treino',
                      style: AppText.pjs(
                        size: 10.5, weight: FontWeight.w700,
                        color: AppColors.blueDark,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '✓ FEITO',
                      style: AppText.pjs(
                        size: 10.5, weight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
        ),
      ),
    );
  }
}
