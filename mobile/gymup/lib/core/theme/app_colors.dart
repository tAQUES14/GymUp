import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Legacy tokens (kept for backward compatibility) ────────────────────────
  static const Color primary      = Color(0xFF2563EB);
  static const Color primaryDark  = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent       = Color(0xFF00C853);
  static const Color error        = Color(0xFFD32F2F);
  static const Color warning      = Color(0xFFFFA000);
  static const Color background   = Color(0xFFF2F4F7);
  static const Color surface      = Colors.white;
  static const Color textPrimary  = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight    = Colors.white;
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Texto (DS) ────────────────────────────────────────────────────────────
  static const ink      = Color(0xFF0E1116);
  static const inkMuted = Color(0xFF5B6472);
  static const inkLight = Color(0xFF9AA3B0);

  // ── Primária azul (DS) ────────────────────────────────────────────────────
  static const blue      = Color(0xFF2F6FED);
  static const blueLight = Color(0xFF4A8CFF);
  static const blueDark  = Color(0xFF1F4FC4);
  static const blueTint  = Color(0xFFE7EEFE);

  // ── Acento lime (DS) ─────────────────────────────────────────────────────
  static const lime = Color(0xFFC8F84A);

  // ── Sucesso verde (DS) ───────────────────────────────────────────────────
  static const green     = Color(0xFF4CAF50);
  static const greenTint = Color(0xFFEDFBD3);

  // ── Alerta laranja (DS) ──────────────────────────────────────────────────
  static const orange     = Color(0xFFFF7A1A);
  static const orangeDark = Color(0xFFB85A00);
  static const orangeTint = Color(0xFFFFEDDC);

  // ── Destaque ouro (DS) ───────────────────────────────────────────────────
  static const gold       = Color(0xFFFFAA00);
  static const yellowTint = Color(0xFFFFF4E5);

  // ── Gradientes (DS) ──────────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blueLight],
  );

  static const gradientPrimaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueDark, blue, blueLight],
    stops: [0, 0.6, 1],
  );

  static const gradientWeekCard = LinearGradient(
    begin: Alignment(0.04, -0.05),
    end: Alignment(0.96, 1.05),
    colors: [blue, blueLight, lime],
    stops: [0.0, 0.55, 1.0],
  );
}
