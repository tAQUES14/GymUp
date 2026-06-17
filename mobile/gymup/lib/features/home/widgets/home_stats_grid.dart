import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeStatsGrid extends StatelessWidget {
  final int points;
  final int checkins;
  final int streak;
  final int bestStreak;
  final int ranking;

  const HomeStatsGrid({
    super.key,
    required this.points,
    required this.checkins,
    required this.streak,
    required this.bestStreak,
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        iconBg: AppColors.blueTint,
        icon: Icons.star_rounded,
        iconColor: AppColors.blue,
        label: 'PONTOS',
        value: _formatPoints(points),
        subtitle: 'pts acumulados',
      ),
      _StatItem(
        iconBg: AppColors.greenTint,
        icon: Icons.how_to_reg_rounded,
        iconColor: AppColors.green,
        label: 'CHECK-INS',
        value: '$checkins',
        subtitle: 'check-ins registrados',
      ),
      _StatItem(
        iconBg: AppColors.orangeTint,
        icon: Icons.local_fire_department_rounded,
        iconColor: AppColors.orange,
        label: 'STREAK',
        value: '$streak dias',
        subtitle: 'seu recorde: $bestStreak',
      ),
      _StatItem(
        iconBg: AppColors.yellowTint,
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.gold,
        label: 'RANKING',
        value: ranking > 0 ? '#$ranking' : '--',
        subtitle: 'por pontos',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.42,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }

  static String _formatPoints(int pts) {
    if (pts < 1000) return '$pts';
    final s = pts.toString();
    if (s.length == 4) return '${s[0]}.${s.substring(1)}';
    if (s.length == 5) return '${s.substring(0, 2)}.${s.substring(2)}';
    return '$pts';
  }
}

class _StatItem {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatItem({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: item.iconColor),
              ),
              Flexible(
                child: Text(
                  item.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pjs(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 142,
                child: Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sg(
                    size: 32,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                    height: 0.96,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 142,
                child: Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pjs(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
