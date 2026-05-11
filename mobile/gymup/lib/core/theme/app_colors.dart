import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF2563EB); // Brand Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Secondary/Accent
  static const Color accent = Color(0xFF00C853); // Success Green
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA); // Light Grey
  static const Color surface = Colors.white;
  
  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
