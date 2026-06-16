import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  final String nome;
  final int points;
  final VoidCallback? onCalendar;
  final VoidCallback? onBell;
  final bool hasNotification;
  final String avatarUrl;

  const HomeHeader({
    super.key,
    required this.nome,
    this.points = 0,
    this.onCalendar,
    this.onBell,
    this.hasNotification = true,
    this.avatarUrl = '',
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'BOM DIA';
    if (hour < 18) return 'BOA TARDE';
    return 'BOA NOITE';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Avatar com gradiente e inicial ────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: avatarUrl.trim().isNotEmpty
                ? Image.network(
                    avatarUrl.trim(),
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    cacheHeight: 120,
                    errorBuilder: (context, error, stackTrace) => _InitialAvatar(nome: nome),
                  )
                : _InitialAvatar(nome: nome),
          ),
        ),

        const SizedBox(width: 12),

        // ── Saudação + nome ───────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: AppText.greeting),
              Text(
                nome,
                style: AppText.pjs(
                  size: 18, weight: FontWeight.w700,
                  color: AppColors.ink, letterSpacing: -0.3, height: 1.1,
                ),
              ),
            ],
          ),
        ),

        // ── Botão calendário ──────────────────────────────────────────────
        _HeaderIconButton(
          onTap: onCalendar,
          child: const Icon(
            Icons.calendar_month_outlined,
            size: 22,
            color: AppColors.ink,
          ),
        ),

        const SizedBox(width: 12),

        // ── Botão notificações ────────────────────────────────────────────
        _HeaderIconButton(
          onTap: onBell,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: AppColors.ink,
              ),
              if (hasNotification)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão quadrado branco com sombra suave — padrão dos ícones do header.
class _InitialAvatar extends StatelessWidget {
  final String nome;

  const _InitialAvatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
        textAlign: TextAlign.center,
        style: AppText.pjs(
          size: 15.1,
          weight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -6,
              top: -1,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0E1116),
                      blurRadius: 0,
                      offset: Offset(0, 0),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
