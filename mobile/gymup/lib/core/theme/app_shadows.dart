import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  static final card = [
    BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.06), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static final buttonBlue = [
    BoxShadow(color: AppColors.blue.withValues(alpha: 0.36), blurRadius: 30, offset: Offset(0, 16)),
  ];

  static const weekCard = [
    BoxShadow(color: Color(0x2E2F6FED), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x472F6FED), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static final navActive = [
    BoxShadow(color: AppColors.blue.withValues(alpha: 0.32), blurRadius: 7, offset: Offset(0, 6)),
  ];

  static final bottomNav = [
    BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.10), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 6,  offset: Offset(0, 2)),
  ];

  static final navBtn = [
    BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.06), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0xFF0E1116).withValues(alpha: 0.04), blurRadius: 0, spreadRadius: 1),
  ];
}
