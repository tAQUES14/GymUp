import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/gymup_loading.dart';
import 'challenge_api_service.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kBlueSoft = Color(0xFFE7EEFE);
const _kLime = Color(0xFFC8F84A);
const _kLimeSoft = Color(0xFFEDFBD3);
const _kGold = Color(0xFFE5A300);
const _kGoldSoft = Color(0xFFFFF8E1);
const _kSilverSoft = Color(0xFFEFF3F8);
const _kBronzeSoft = Color(0xFFF8E3D0);
const _kRed = Color(0xFFD14343);

class ChallengeDetailsPage extends StatefulWidget {
  final ChallengeData challenge;

  const ChallengeDetailsPage({super.key, required this.challenge});

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  List<ChallengeRankingEntry>? _ranking;
  int? _currentUserId;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final ranking = await ChallengeApiService().getRanking(widget.challenge.id);
      if (!mounted) return;
      setState(() {
        _currentUserId = prefs.getInt('user_id');
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ranking = [];
        _isLoading = false;
        _hasError = true;
      });
    }
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
                onRefresh: _loadRanking,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 34 + bottomInset),
                  children: [
                    _Header(onBack: () => Navigator.pop(context), onRefresh: _loadRanking),
                    const SizedBox(height: 18),
                    _ChallengeHero(challenge: widget.challenge),
                    const SizedBox(height: 24),
                    Text(
                      'Seu progresso',
                      style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 12),
                    _ProgressCard(challenge: widget.challenge),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          'Ranking',
                          style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                        ),
                        const Spacer(),
                        if (_ranking != null && _ranking!.isNotEmpty)
                          _CountPill(count: _ranking!.length),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_hasError)
                      _StateCard(
                        icon: Icons.wifi_off_rounded,
                        title: 'Ranking indispon\u00EDvel',
                        subtitle: 'N\u00E3o foi poss\u00EDvel carregar os participantes.',
                        color: _kRed,
                      )
                    else if (_ranking == null || _ranking!.isEmpty)
                      _StateCard(
                        icon: Icons.emoji_events_outlined,
                        title: 'Sem participantes',
                        subtitle: 'Quando algu\u00E9m pontuar, o ranking aparece aqui.',
                        color: _kBlue,
                      )
                    else ...[
                      for (final entry in _ranking!.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RankingRow(
                            entry: entry,
                            isCompetitive: widget.challenge.isCompetitive,
                            isMe: entry.userId == _currentUserId,
                          ),
                        ),
                      if (_ranking!.length > 3) ...[
                        const SizedBox(height: 4),
                        _FullRankingButton(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _FullChallengeRankingPage(
                                entries: _ranking!,
                                isCompetitive: widget.challenge.isCompetitive,
                                currentUserId: _currentUserId,
                              ),
                            ),
                          ),
                        ),
                      ],
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
            'Desafio',
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

class _ChallengeHero extends StatelessWidget {
  final ChallengeData challenge;

  const _ChallengeHero({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysLeft(challenge.endsAt);
    final subtitle = (challenge.description ?? '').trim().isEmpty
        ? (challenge.isCompetitive ? 'Que ven\u00E7a o melhor.' : 'Complete o objetivo e ganhe pontos.')
        : challenge.description!.trim();
    final participants = challenge.isCompetitive ? 12 : null;

    return Container(
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.13, -0.03),
          end: Alignment(0.77, 0.83),
          colors: [Color(0xFF3272EF), Color(0xFF498BFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: _shadow(),
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
                child: Center(
                  child: challenge.isCompetitive
                      ? SvgPicture.asset(
                          'assets/icons/challenges/trophy.svg',
                          width: 22,
                          height: 22,
                        )
                      : const Icon(Icons.flag_rounded, color: _kGold, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kBlueSoft, borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _kLime,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.68), blurRadius: 6)],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            challenge.isCompetitive ? 'DESAFIO COMPETITIVO' : 'DESAFIO SIMPLES',
                            style: _pjs(size: 9.5, weight: FontWeight.w800, color: _kBlueDark, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _pjs(size: 19, weight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _pjs(size: 13, weight: FontWeight.w500, color: const Color(0xFFECECEC), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroMeta(icon: Icons.schedule_rounded, value: '$daysLeft dias', label: 'restantes'),
              const SizedBox(width: 14),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 14),
              _HeroMeta(
                icon: Icons.groups_rounded,
                value: participants?.toString() ?? '-',
                label: 'participantes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMeta({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 6),
        Text(value, style: _sg(size: 12, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1)),
        const SizedBox(width: 4),
        Text(label, style: _pjs(size: 12, weight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ChallengeData challenge;

  const _ProgressCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final isCompetitive = challenge.isCompetitive;
    final current = isCompetitive ? (challenge.myWorkoutsThisWeek ?? 0) : (challenge.myWorkouts ?? 0);
    final goal = isCompetitive ? (challenge.maxWeeklyWorkouts ?? 1) : (challenge.goalWorkouts ?? 1);
    final points = isCompetitive ? (challenge.myTotalPoints ?? 0) : (challenge.rewardPoints ?? 0);
    final position = challenge.myPosition ?? 0;
    final progress = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: _kGoldSoft, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Text(
                  position > 0 ? '$position\u00BA' : '-',
                  style: _sg(size: 13, weight: FontWeight.w700, color: _kGold, letterSpacing: -0.2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUA POSI\u00C7\u00C3O', style: _pjs(size: 10.5, weight: FontWeight.w800, color: _kSoft, letterSpacing: 0.4)),
                    const SizedBox(height: 1),
                    Text(
                      position > 0 ? '$position\u00BA lugar' : 'Entre no ranking',
                      style: _pjs(size: 15, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: _sg(size: 14, weight: FontWeight.w700, color: _kBlue, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _kInk.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _kInk.withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProgressMetric(
                  icon: Icons.fitness_center_rounded,
                  bg: _kBlueSoft,
                  value: '$current',
                  suffix: '/ $goal',
                  label: isCompetitive ? 'treinos esta semana' : 'treinos no desafio',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ProgressMetric(
                  icon: Icons.star_rounded,
                  asset: 'assets/icons/challenges/points.svg',
                  bg: _kLimeSoft,
                  value: '$points',
                  suffix: 'pts',
                  label: isCompetitive ? 'acumulados' : 'recompensa',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final Color bg;
  final String value;
  final String suffix;
  final String label;

  const _ProgressMetric({
    required this.icon,
    this.asset,
    required this.bg,
    required this.value,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: asset == null
                ? Icon(icon, color: _kBlue, size: 15)
                : SvgPicture.asset(asset!, width: 15, height: 15),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: _sg(size: 17, weight: FontWeight.w700, color: _kInk, height: 1, letterSpacing: -0.4)),
                  const SizedBox(width: 3),
                  Flexible(child: Text(suffix, style: _sg(size: 11, weight: FontWeight.w700, color: _kSoft))),
                ],
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 11, weight: FontWeight.w600, color: _kMuted, letterSpacing: -0.1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final ChallengeRankingEntry entry;
  final bool isCompetitive;
  final bool isMe;

  const _RankingRow({
    required this.entry,
    required this.isCompetitive,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final points = isCompetitive ? (entry.totalPoints ?? 0) : (entry.workouts ?? 0);
    final positionBg = switch (entry.position) {
      1 => const Color(0x66FFF8E1),
      2 => _kSilverSoft,
      3 => _kBronzeSoft,
      _ => Colors.white,
    };
    final positionColor = switch (entry.position) {
      1 => const Color(0xFF7A4A00),
      2 => const Color(0xFF3D4A5C),
      3 => const Color(0xFF5C3415),
      _ => _kMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: entry.position == 1 ? const Color(0x66FFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: entry.position == 1 ? Border.all(color: const Color(0xFFFFD56B)) : null,
        boxShadow: entry.position == 1
            ? [
                BoxShadow(color: _kGold.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6)),
              ]
            : _shadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: positionBg,
              gradient: entry.position == 1
                  ? const LinearGradient(colors: [Color(0xFFFFE9A1), Color(0xFFFFD56B)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                  : null,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${entry.position}', style: _sg(size: 13, weight: FontWeight.w700, color: positionColor, letterSpacing: -0.2)),
          ),
          const SizedBox(width: 12),
          _Avatar(name: entry.userName, seed: entry.position),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 14, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  _MePill(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$points ', style: _sg(size: 14, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2)),
          Text(isCompetitive ? 'pts' : 'treinos', style: _sg(size: 11, weight: FontWeight.w700, color: _kSoft, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final int seed;

  const _Avatar({required this.name, required this.seed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _avatarGradient(seed), begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(_initials(name), style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
    );
  }
}

class _MePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(100)),
      child: Text('VOC\u00CA', style: _pjs(size: 9.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
    );
  }
}

class _FullRankingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FullRankingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 14, left: 14, right: 14, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kInk.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ver ranking completo', style: _pjs(size: 13.5, weight: FontWeight.w800, color: _kBlue, letterSpacing: -0.2)),
            const SizedBox(width: 7),
            const Icon(Icons.arrow_forward_rounded, color: _kBlue, size: 15),
          ],
        ),
      ),
    );
  }
}

class _FullChallengeRankingPage extends StatelessWidget {
  final List<ChallengeRankingEntry> entries;
  final bool isCompetitive;
  final int? currentUserId;

  const _FullChallengeRankingPage({
    required this.entries,
    required this.isCompetitive,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
          children: [
            Row(
              children: [
                _CircleButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Text(
                    'Ranking',
                    textAlign: TextAlign.center,
                    style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                  ),
                ),
                _CountPill(count: entries.length),
              ],
            ),
            const SizedBox(height: 20),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RankingRow(
                  entry: entry,
                  isCompetitive: isCompetitive,
                  isMe: entry.userId == currentUserId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: _kInk.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(100)),
      child: Text('$count', style: _sg(size: 11, weight: FontWeight.w700, color: _kMuted)),
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
      padding: const EdgeInsets.all(18),
      decoration: _whiteDecoration(18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(title, style: _pjs(size: 15, weight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: _pjs(size: 12, weight: FontWeight.w500, color: _kMuted, height: 1.4)),
        ],
      ),
    );
  }
}

int _daysLeft(String raw) {
  final end = DateTime.tryParse(raw);
  if (end == null) return 0;
  final now = DateTime.now();
  return end.difference(now).inDays.clamp(0, 999);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

List<Color> _avatarGradient(int seed) {
  return switch (seed) {
    1 => const [Color(0xFF2F6FED), Color(0xFF4A8CFF)],
    2 => const [Color(0xFFE859A1), Color(0xFFFF8FBC)],
    3 => const [Color(0xFF0E9F8B), Color(0xFF4FD1B8)],
    4 => const [Color(0xFF7A5AE0), Color(0xFFA98EFF)],
    _ => const [Color(0xFFFF7A5C), Color(0xFFFFAB8A)],
  };
}

BoxDecoration _whiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: _shadow(),
  );
}

List<BoxShadow> _shadow({bool tight = false}) {
  return [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    if (!tight)
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
  ];
}

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _sg({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
