import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'achievement_api_service.dart';

const _kBlue = Color(0xFF2563EB);

class AchievementsList extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsList({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AchievementItem(achievement: achievements[i]),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nenhuma conquista disponível',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue treinando para desbloquear conquistas.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final Achievement achievement;

  const _AchievementItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    if (achievement.unlocked)     return _buildUnlocked();
    if (achievement.isInProgress) return _buildInProgress();
    return _buildLocked();
  }

  // ── 1. DESBLOQUEADA ───────────────────────────────────────────────────────

  Widget _buildUnlocked() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral verde
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    // Ícone
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            achievement.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '+${achievement.pointsReward} pts',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Feita',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. EM PROGRESSO ───────────────────────────────────────────────────────

  Widget _buildInProgress() {
    final ratio = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlue.withValues(alpha: 0.20)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral azul
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: _kBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Conteúdo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  achievement.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${achievement.progress}/${achievement.target}',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _kBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Barra de progresso
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 7,
                              backgroundColor: _kBlue.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_outline_rounded,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '+${achievement.pointsReward} pts ao completar',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$percent%',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. BLOQUEADA ──────────────────────────────────────────────────────────
  // Sem Opacity widget — contraste acessível via cores neutras diretas

  Widget _buildLocked() {
    const textMuted    = Color(0xFF9CA3AF); // gray-400
    const bgColor      = Color(0xFFF9FAFB); // gray-50
    const borderColor  = Color(0xFFE5E7EB); // gray-200
    const iconBgColor  = Color(0xFFE5E7EB);
    const iconColor    = Color(0xFFD1D5DB); // gray-300

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral cinza tracejada (simulada com cor)
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    // Ícone cadeado
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            achievement.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: AppTypography.caption.copyWith(
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_outline_rounded, size: 12, color: textMuted),
                              const SizedBox(width: 3),
                              Text(
                                '+${achievement.pointsReward} pts',
                                style: AppTypography.caption.copyWith(
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Meta
                    Text(
                      '0/${achievement.target}',
                      style: AppTypography.caption.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
