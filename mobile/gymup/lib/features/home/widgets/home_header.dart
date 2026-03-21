import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

const _kBlue = Color(0xFF2563EB);

class HomeHeader extends StatelessWidget {
  final String nome;
  final int points;

  const HomeHeader({
    super.key,
    required this.nome,
    this.points = 0,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _firstName => nome.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar com inicial
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: _kBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Saudação
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _firstName,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Badge de pontos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                '$points pts',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
