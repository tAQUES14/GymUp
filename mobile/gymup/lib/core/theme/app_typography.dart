import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const _pjs = 'Plus Jakarta Sans';

  static TextStyle get h1 => const TextStyle(
        fontFamily: _pjs,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.7,
      );

  static TextStyle get h2 => const TextStyle(
        fontFamily: _pjs,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.45,
      );

  static TextStyle get h3 => const TextStyle(
        fontFamily: _pjs,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _pjs,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _pjs,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: _pjs,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      );
      
  static TextStyle get caption => const TextStyle(
        fontFamily: _pjs,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );
}
