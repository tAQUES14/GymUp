import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum GymFeedbackKind { success, error, warning, info }

Color _feedbackColor(GymFeedbackKind kind) {
  return switch (kind) {
    GymFeedbackKind.success => AppColors.green,
    GymFeedbackKind.error => AppColors.error,
    GymFeedbackKind.warning => AppColors.orange,
    GymFeedbackKind.info => AppColors.blue,
  };
}

IconData _feedbackIcon(GymFeedbackKind kind) {
  return switch (kind) {
    GymFeedbackKind.success => Icons.check_rounded,
    GymFeedbackKind.error => Icons.close_rounded,
    GymFeedbackKind.warning => Icons.priority_high_rounded,
    GymFeedbackKind.info => Icons.info_outline_rounded,
  };
}

void showGymSnack(
  BuildContext context,
  String message, {
  GymFeedbackKind kind = GymFeedbackKind.error,
  Duration duration = const Duration(seconds: 4),
}) {
  final color = _feedbackColor(kind);
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_feedbackIcon(kind), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.pjs(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> showGymConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
  IconData icon = Icons.info_outline_rounded,
  Color color = AppColors.blue,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppText.pjs(
                  size: 20,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppText.pjs(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        cancelLabel,
                        textAlign: TextAlign.center,
                        style: AppText.pjs(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destructive ? AppColors.error : color,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: AppText.pjs(size: 13, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}
