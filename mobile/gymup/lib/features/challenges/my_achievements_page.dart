import 'package:flutter/material.dart';

import '../../core/widgets/gymup_loading.dart';
import 'achievement_api_service.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlue2 = Color(0xFF4A8CFF);
const _kBlueSoft = Color(0xFFE7EEFE);
const _kGold = Color(0xFFE5A300);
const _kGoldSoft = Color(0xFFFFF8E1);
const _kGreen = Color(0xFF0E9F6E);
const _kGreenSoft = Color(0xFFEAF8EF);
const _kOrange = Color(0xFFFF8A00);
const _kOrangeSoft = Color(0xFFFFF4E4);
const _kRed = Color(0xFFD14343);

enum _AchievementFilter { all, unlocked, progress, locked }

class MyAchievementsPage extends StatefulWidget {
  final List<Achievement>? initialAchievements;

  const MyAchievementsPage({super.key, this.initialAchievements});

  @override
  State<MyAchievementsPage> createState() => _MyAchievementsPageState();
}

class _MyAchievementsPageState extends State<MyAchievementsPage> {
  final _api = AchievementApiService();

  late List<Achievement> _achievements;
  var _filter = _AchievementFilter.all;
  var _isLoading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _achievements = _sort(widget.initialAchievements ?? const []);
    _isLoading = widget.initialAchievements == null;
    _load();
  }

  Future<void> _load() async {
    if (widget.initialAchievements == null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final achievements = await _api.getAchievements();
      if (!mounted) return;
      setState(() {
        _achievements = _sort(achievements);
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = _achievements.isEmpty;
      });
    }
  }

  List<Achievement> _sort(List<Achievement> achievements) {
    return [
      ...achievements.where((a) => a.unlocked),
      ...achievements.where((a) => a.isInProgress),
      ...achievements.where((a) => a.isLocked),
    ];
  }

  List<Achievement> get _filtered {
    return switch (_filter) {
      _AchievementFilter.all => _achievements,
      _AchievementFilter.unlocked => _achievements.where((a) => a.unlocked).toList(),
      _AchievementFilter.progress => _achievements.where((a) => a.isInProgress).toList(),
      _AchievementFilter.locked => _achievements.where((a) => a.isLocked).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const GymUpLoading()
            : RefreshIndicator(
                color: _kBlue,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 34 + bottomInset),
                  children: [
                    _Header(onBack: () => Navigator.pop(context), onRefresh: _load),
                    const SizedBox(height: 18),
                    if (_hasError)
                      _StateCard(
                        icon: Icons.wifi_off_rounded,
                        title: 'Conquistas indispon\u00EDveis',
                        subtitle: 'N\u00E3o foi poss\u00EDvel atualizar sua lista agora.',
                        color: _kRed,
                      )
                    else ...[
                      _SummaryCard(achievements: _achievements),
                      const SizedBox(height: 18),
                      _OverviewStats(achievements: _achievements),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Desafios pessoais',
                              style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                            ),
                          ),
                          Text(
                            '${_filtered.length} itens',
                            style: _sg(size: 12, weight: FontWeight.w700, color: _kSoft, letterSpacing: -0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FilterBar(
                        selected: _filter,
                        achievements: _achievements,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 14),
                      if (_filtered.isEmpty)
                        _StateCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Nada por aqui ainda',
                          subtitle: 'Continue treinando para liberar novas conquistas.',
                          color: _kBlue,
                        )
                      else
                        for (final achievement in _filtered)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AchievementCard(achievement: achievement),
                          ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Text(
            'Minhas conquistas',
            textAlign: TextAlign.center,
            style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
          ),
        ),
        _CircleButton(icon: Icons.refresh_rounded, onTap: onRefresh),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _shadow(tight: true),
        ),
        child: Icon(icon, color: _kInk, size: 19),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Achievement> achievements;

  const _SummaryCard({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final total = achievements.length;
    final unlocked = achievements.where((a) => a.unlocked).length;
    final streakCount = achievements.where((a) => a.isStreak).length;
    final workoutCount = achievements.where((a) => a.isWorkout).length;
    final points = achievements
        .where((a) => a.unlocked)
        .fold<int>(0, (sum, achievement) => sum + achievement.pointsReward);
    final ratio = total == 0 ? 0.0 : unlocked / total;
    final percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlue2],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: _shadow(color: _kBlue.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _kGoldSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x3FFFD56B)),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: _kGold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlueSoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'DESAFIOS PESSOAIS',
                        style: _pjs(size: 9.5, weight: FontWeight.w800, color: _kBlue, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unlocked de $total conquistas',
                      style: _pjs(size: 19, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$workoutCount treinos, $streakCount streaks e $points pts acumulados.',
                      style: _pjs(size: 13, weight: FontWeight.w500, color: const Color(0xFFECECEC), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso geral',
                style: _pjs(size: 11, weight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.78), letterSpacing: 0.4),
              ),
              Text(
                '$percent%',
                style: _sg(size: 14, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryMiniStat(label: 'Treinos', value: '$workoutCount'),
              const SizedBox(width: 8),
              _SummaryMiniStat(label: 'Streak', value: '$streakCount'),
              const SizedBox(width: 8),
              _SummaryMiniStat(label: 'Pontos', value: '$points'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: _sg(size: 16, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pjs(size: 10.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.76), letterSpacing: -0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStats extends StatelessWidget {
  final List<Achievement> achievements;

  const _OverviewStats({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.unlocked).length;
    final progress = achievements.where((a) => a.isInProgress).length;
    final locked = achievements.where((a) => a.isLocked).length;

    return Row(
      children: [
        _OverviewStat(
          icon: Icons.check_circle_rounded,
          label: 'Feitas',
          value: '$unlocked',
          color: _kGreen,
          bg: _kGreenSoft,
        ),
        const SizedBox(width: 8),
        _OverviewStat(
          icon: Icons.bolt_rounded,
          label: 'Progresso',
          value: '$progress',
          color: _kBlue,
          bg: _kBlueSoft,
        ),
        const SizedBox(width: 8),
        _OverviewStat(
          icon: Icons.lock_outline_rounded,
          label: 'Bloq.',
          value: '$locked',
          color: _kSoft,
          bg: const Color(0xFFEFF3F8),
        ),
      ],
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _OverviewStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x140E1116)),
          boxShadow: _shadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: _sg(size: 15, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3)),
                  const SizedBox(height: 1),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 10.5, weight: FontWeight.w700, color: _kSoft, letterSpacing: -0.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _AchievementFilter selected;
  final List<Achievement> achievements;
  final ValueChanged<_AchievementFilter> onChanged;

  const _FilterBar({
    required this.selected,
    required this.achievements,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x0C0E1116),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'Todas',
              count: achievements.length,
              selected: selected == _AchievementFilter.all,
              onTap: () => onChanged(_AchievementFilter.all),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Feitas',
              count: achievements.where((a) => a.unlocked).length,
              selected: selected == _AchievementFilter.unlocked,
              onTap: () => onChanged(_AchievementFilter.unlocked),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Prog.',
              count: achievements.where((a) => a.isInProgress).length,
              selected: selected == _AchievementFilter.progress,
              onTap: () => onChanged(_AchievementFilter.progress),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Bloq.',
              count: achievements.where((a) => a.isLocked).length,
              selected: selected == _AchievementFilter.locked,
              onTap: () => onChanged(_AchievementFilter.locked),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected ? _shadow(color: _kBlue.withValues(alpha: 0.22), tight: true) : null,
        ),
        child: Center(
          child: Text(
            '$label $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pjs(
              size: 12,
              weight: FontWeight.w800,
              color: selected ? Colors.white : _kMuted,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final ratio = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;
    final isUnlocked = achievement.unlocked;
    final isProgress = achievement.isInProgress;
    final typeColor = achievement.isStreak ? _kOrange : _kBlue;
    final typeSoft = achievement.isStreak ? _kOrangeSoft : _kBlueSoft;
    final stateColor = isUnlocked ? _kGreen : (isProgress ? _kBlue : _kSoft);
    final stateSoft = isUnlocked ? _kGreenSoft : (isProgress ? _kBlueSoft : const Color(0xFFEFF3F8));
    final icon = achievement.isStreak ? Icons.bolt_rounded : Icons.format_list_bulleted_rounded;
    final badgeLabel = achievement.isStreak ? 'Streak' : 'Treinos';
    final stateLabel = isUnlocked ? 'FEITA' : (isProgress ? 'EM PROGRESSO' : 'BLOQUEADA');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isProgress ? _kBlue.withValues(alpha: 0.18) : const Color(0x140E1116)),
        boxShadow: _shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: typeColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: _pjs(size: 14.5, weight: FontWeight.w800, color: isUnlocked || isProgress ? _kInk : _kSoft, letterSpacing: -0.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TinyPill(label: badgeLabel, fg: typeColor, bg: typeSoft),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: _pjs(size: 12, weight: FontWeight.w500, color: isUnlocked || isProgress ? _kMuted : _kSoft, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: const Color(0x0F0E1116),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TinyPill(label: stateLabel, fg: stateColor, bg: stateSoft),
                        const SizedBox(width: 8),
                        Text(
                          '+${achievement.pointsReward} pts',
                          style: _sg(size: 12, weight: FontWeight.w700, color: typeColor, letterSpacing: -0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: const Color(0x0F0E1116),
                        valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${achievement.progress}',
                    style: _sg(size: 18, weight: FontWeight.w700, color: isUnlocked || isProgress ? _kInk : _kSoft, letterSpacing: -0.4),
                  ),
                  Text(
                    '/ ${achievement.target}',
                    style: _sg(size: 11, weight: FontWeight.w700, color: _kSoft, letterSpacing: -0.1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _TinyPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: fg.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _pjs(size: 9.5, weight: FontWeight.w800, color: fg, letterSpacing: 0.35),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x140E1116)),
        boxShadow: _shadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _pjs(size: 14.5, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(subtitle, style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  required Color color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _sg({
  required double size,
  required FontWeight weight,
  required Color color,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontFamily: 'Space Grotesk',
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}

List<BoxShadow> _shadow({Color? color, bool tight = false}) {
  return [
    BoxShadow(
      color: color ?? const Color(0x0A0F172A),
      blurRadius: tight ? 8 : 6,
      offset: Offset(0, tight ? 2 : 2),
    ),
    if (!tight)
      const BoxShadow(
        color: Color(0x0F0F172A),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
  ];
}
