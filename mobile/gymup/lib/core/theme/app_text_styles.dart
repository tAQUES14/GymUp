import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppText {
  static const _pjs = 'Plus Jakarta Sans';
  static const _sg = 'Space Grotesk';

  // Plus Jakarta Sans
  static const sectionTitle = TextStyle(
    fontFamily: _pjs,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const itemTitle = TextStyle(
    fontFamily: _pjs,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  static const timelineTitle = TextStyle(
    fontFamily: _pjs,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  static const heroTitle = TextStyle(
    fontFamily: _pjs,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const userName = TextStyle(
    fontFamily: _pjs,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static const subtitle = TextStyle(
    fontFamily: _pjs,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
  );

  static const subtitleWhite = TextStyle(
    fontFamily: _pjs,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const cardLabel = TextStyle(
    fontFamily: _pjs,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.inkMuted,
    letterSpacing: 0.4,
  );

  static const greeting = TextStyle(
    fontFamily: _pjs,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkLight,
    letterSpacing: 0.2,
  );

  static const badge = TextStyle(
    fontFamily: _pjs,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const weekDay = TextStyle(
    fontFamily: _pjs,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const link = TextStyle(
    fontFamily: _pjs,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.blue,
  );

  // Space Grotesk
  static const metricHero = TextStyle(
    fontFamily: _sg,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -2.5,
    height: 0.95,
  );

  static const metricHeroSub = TextStyle(
    fontFamily: _sg,
    fontSize: 27.8,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -1,
    height: 0.95,
  );

  static const statValue = TextStyle(
    fontFamily: _sg,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1,
  );

  static const metricSmall = TextStyle(
    fontFamily: _sg,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.blue,
  );

  static const ringValue = TextStyle(
    fontFamily: _sg,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static TextStyle pjs({
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _pjs,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle sg({
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _sg,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: letterSpacing,
        height: height,
      );
}
