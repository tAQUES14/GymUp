import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import 'ranking_api_service.dart';
import 'ranking_periodo.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kLime = Color(0xFFC8F84A);
const _kGreen = Color(0xFF5BA300);
const _kRed = Color(0xFFEF4444);
const _kCrownSvg = '''
<svg width="19" height="16" viewBox="0 0 19 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M0.916748 3.6665L4.58341 8.24984L9.16675 0.916504L13.7501 8.24984L17.4167 3.6665L15.5834 14.6665H2.75008L0.916748 3.6665Z" fill="#FFD56B" stroke="#E5A300" stroke-width="1.83333" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final _service = RankingApiService();
  RankingPeriodo _periodo = RankingPeriodo.semanal;
  RankingEscopo _escopo = RankingEscopo.gym;
  List<RankingItem> _ranking = [];
  int? _currentUserId;
  String _currentUserName = 'Marcos Silva';
  bool _hasChain = false;
  bool _isLoading = false;
  String? _error;
  Future<void>? _activeFetch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadNetworkInfo();
      _loadRanking();
    });
  }

  Future<void> _loadNetworkInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserName = prefs.getString('user_name') ?? _currentUserName;
    var chainId = prefs.getInt('gym_chain_id');

    if (chainId == null && prefs.getString('auth_token') != null) {
      try {
        await AuthApiService().getMe();
        chainId = prefs.getInt('gym_chain_id');
      } catch (_) {}
    }

    if (mounted) setState(() => _hasChain = chainId != null);
  }

  Future<void> _loadRanking() async {
    if (_activeFetch != null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _activeFetch = _executeFetch();
      await _activeFetch;
    } finally {
      _activeFetch = null;
    }
  }

  void _changePeriod(RankingPeriodo period) {
    if (_periodo == period || _activeFetch != null) return;
    setState(() {
      _periodo = period;
      _isLoading = true;
      _error = null;
    });
    _activeFetch = _executeFetch();
    _activeFetch!.whenComplete(() => _activeFetch = null);
  }

  void _changeScope(RankingEscopo scope) {
    if (_escopo == scope || _activeFetch != null) return;
    setState(() {
      _escopo = scope;
      _isLoading = true;
      _error = null;
    });
    _activeFetch = _executeFetch();
    _activeFetch!.whenComplete(() => _activeFetch = null);
  }

  Future<void> _executeFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      _currentUserName = prefs.getString('user_name') ?? _currentUserName;
      final items = await _service.getRanking(
        period: _periodo.param,
        scope: _escopo.param,
      );
      if (!mounted) return;
      setState(() {
        _ranking = items;
        _isLoading = false;
      });
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '401' && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar ranking: $msg')),
      );
      setState(() {
        _error = msg;
        _isLoading = false;
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
        child: RefreshIndicator(
          color: _kBlue,
          onRefresh: _loadRanking,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, 112 + bottomInset),
            children: [
              _header(),
              const SizedBox(height: 14),
              _periodSelector(),
              if (_hasChain) ...[
                const SizedBox(height: 10),
                _scopeSelector(),
              ],
              const SizedBox(height: 14),
              if (_isLoading)
                const SizedBox(height: 420, child: GymUpLoading())
              else if (_error != null)
                _ErrorCard(error: _error!, onRetry: _loadRanking)
              else if (_ranking.isEmpty)
                const _EmptyCard()
              else
                _RankingContent(
                  ranking: _ranking,
                  currentUserId: _currentUserId,
                  currentUserName: _currentUserName,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final title = switch (_periodo) {
      RankingPeriodo.semanal => 'Competi\u00E7\u00E3o da semana',
      RankingPeriodo.mensal => 'Competi\u00E7\u00E3o do m\u00EAs',
      _ => 'Competi\u00E7\u00E3o geral',
    };

    return Row(
      children: [
        _avatar(
          initials: _initials(_currentUserName),
          size: 40,
          gradient: const [Color(0xFF2F6FED), Color(0xFF4A8CFF)],
          fontSize: 14.4,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RANKING',
                style: _pjs(size: 11, weight: FontWeight.w600, color: _kSoft, letterSpacing: 0.6),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 19, weight: FontWeight.w700, color: _kInk, height: 1.05, letterSpacing: -0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periodSelector() {
    final tabs = [
      (RankingPeriodo.semanal, 'Semanal'),
      (RankingPeriodo.mensal, 'Mensal'),
      (RankingPeriodo.all, 'Geral'),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _SelectorPill(
                label: tab.$2,
                selected: _periodo == tab.$1,
                onTap: () => _changePeriod(tab.$1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scopeSelector() {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (final scope in RankingEscopo.values) ...[
            Expanded(
              child: _SmallSelectorPill(
                label: scope.label,
                selected: _escopo == scope,
                onTap: () => _changeScope(scope),
              ),
            ),
            if (scope != RankingEscopo.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _RankingContent extends StatelessWidget {
  final List<RankingItem> ranking;
  final int? currentUserId;
  final String currentUserName;

  const _RankingContent({
    required this.ranking,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final current = _currentItem();
    final sorted = [...ranking]..sort((a, b) => a.position.compareTo(b.position));
    final top3 = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PositionHero(item: current, currentUserName: currentUserName),
        const SizedBox(height: 24),
        Text(
          'Top alunos',
          style: _pjs(size: 17, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
        ),
        const SizedBox(height: 14),
        if (top3.isNotEmpty) _PodiumCard(top3: top3, currentUserId: currentUserId),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Ranking da academia',
              style: _pjs(size: 17, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
            ),
            const SizedBox(width: 10),
            _countPill(ranking.length),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _RankingFullListPage(
                      ranking: sorted,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Ver tudo', style: _pjs(size: 13, weight: FontWeight.w600, color: _kBlue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final item in sorted.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RankingRow(item: item, isMe: item.userId == currentUserId),
          ),
      ],
    );
  }

  RankingItem _currentItem() {
    if (currentUserId != null) {
      for (final item in ranking) {
        if (item.userId == currentUserId) return item;
      }
    }
    return RankingItem(
      position: ranking.length + 1,
      userId: currentUserId ?? -1,
      name: currentUserName,
      points: 0,
      streak: 0,
    );
  }
}

class _PositionHero extends StatelessWidget {
  final RankingItem item;
  final String currentUserName;

  const _PositionHero({required this.item, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 264,
      padding: const EdgeInsets.fromLTRB(22, 48, 22, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.07, -0.11),
          end: Alignment(0.93, 1.11),
          colors: [_kBlue, Color(0xFF4A8CFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 18,
            top: 34,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 0.5),
                    child: const Icon(Icons.trending_up_rounded, color: _kLime, size: 11),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SUA POSI\u00C7\u00C3O',
                    style: _pjs(size: 10.5, weight: FontWeight.w700, color: _kLime, letterSpacing: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '#',
                    style: _sg(size: 28, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.70), height: 0.95, letterSpacing: -1),
                  ),
                  Text(
                    '${item.position}',
                    style: _sg(size: 56, weight: FontWeight.w700, color: Colors.white, height: 0.95, letterSpacing: -2.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.name.isEmpty ? currentUserName : item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 18, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                '${_fmtPoints(item.points)} pts',
                style: _sg(size: 13, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: _kLime, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.workspace_premium_rounded, color: _kBlueDark, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Voc\u00EA est\u00E1 no ', style: _pjs(size: 12.5, weight: FontWeight.w600, color: Colors.white)),
                            TextSpan(text: 'Top ${item.position}', style: _pjs(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                            TextSpan(text: ' da academia', style: _pjs(size: 12.5, weight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    _growthBadge(item),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final List<RankingItem> top3;
  final int? currentUserId;

  const _PodiumCard({required this.top3, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: _whiteDecoration(22),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox(height: 225)
                : _PodiumSlot(
                    item: second,
                    rank: 2,
                    slotHeight: 225,
                    avatarSize: 52,
                    avatarTop: 0,
                    nameTop: 88,
                    pointsTop: 106,
                    barTop: 135,
                    barHeight: 90,
                    isMe: second.userId == currentUserId,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumSlot(
              item: first,
              rank: 1,
              slotHeight: 292,
              avatarSize: 64,
              avatarTop: 34,
              nameTop: 124,
              pointsTop: 142,
              barTop: 170,
              barHeight: 122,
              isMe: first.userId == currentUserId,
              crown: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: third == null
                ? const SizedBox(height: 225)
                : _PodiumSlot(
                    item: third,
                    rank: 3,
                    slotHeight: 225,
                    avatarSize: 52,
                    avatarTop: 0,
                    nameTop: 88,
                    pointsTop: 106,
                    barTop: 155,
                    barHeight: 70,
                    isMe: third.userId == currentUserId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final RankingItem item;
  final int rank;
  final double slotHeight;
  final double avatarSize;
  final double avatarTop;
  final double nameTop;
  final double pointsTop;
  final double barTop;
  final double barHeight;
  final bool isMe;
  final bool crown;

  const _PodiumSlot({
    required this.item,
    required this.rank,
    required this.slotHeight,
    required this.avatarSize,
    required this.avatarTop,
    required this.nameTop,
    required this.pointsTop,
    required this.barTop,
    required this.barHeight,
    required this.isMe,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    final compactFirst = rank == 1 && isMe;
    final effectiveAvatarTop = compactFirst ? 34.0 : avatarTop;
    final effectiveNameTop = compactFirst ? 124.0 : nameTop;
    final effectivePointsTop = compactFirst ? 158.0 : pointsTop;
    final effectiveBarTop = compactFirst ? 182.0 : barTop;
    final effectiveBarHeight = compactFirst ? 110.0 : barHeight;
    final badgeTop = compactFirst ? 141.0 : pointsTop + 20;

    return SizedBox(
      height: slotHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: effectiveBarTop,
            left: 0,
            right: 0,
            child: Container(
              height: effectiveBarHeight,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_rankLight(rank), _rankBase(rank)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              alignment: Alignment.topCenter,
              child: Text(
                '$rank\u00BA',
                style: _sg(size: rank == 1 ? 26 : 22, weight: FontWeight.w700, color: _rankText(rank), letterSpacing: -0.5),
              ),
            ),
          ),
          Positioned(
            top: effectiveNameTop,
            left: 2,
            right: 2,
            child: Text(
              _shortName(item.name),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pjs(size: 12.5, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
            ),
          ),
          Positioned(
            top: effectivePointsTop,
            left: 2,
            right: 2,
            child: Text(
              '${_fmtPoints(item.points)} pts',
              textAlign: TextAlign.center,
              style: _sg(size: 11, weight: FontWeight.w700, color: _kMuted, letterSpacing: -0.1),
            ),
          ),
          if (isMe)
            Positioned(
              top: badgeTop,
              child: _mePill(),
            ),
          Positioned(
            top: effectiveAvatarTop,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(rank == 1 || isMe ? 3 : 0),
                  decoration: BoxDecoration(
                    gradient: rank == 1
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD56B), Color(0xFFE5A300)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : isMe
                            ? const LinearGradient(
                                colors: [_kBlue, _kLime],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: _avatar(
                    initials: _initials(item.name),
                    size: avatarSize,
                    gradient: _avatarGradient(rank),
                    fontSize: avatarSize * 0.36,
                  ),
                ),
                Positioned(
                  left: (avatarSize + (rank == 1 || isMe ? 6 : 0)) / 2 - 13,
                  bottom: -10,
                  child: _rankBubble(rank),
                ),
              ],
            ),
          ),
          if (crown)
            Positioned(
              top: 5,
              child: SvgPicture.string(
                _kCrownSvg,
                width: 30,
                height: 25,
              ),
            ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final RankingItem item;
  final bool isMe;

  const _RankingRow({required this.item, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE7EEFE) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isMe ? Border.all(color: _kBlue) : null,
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : _shadow(),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              item.position.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: _sg(
                size: 16,
                weight: FontWeight.w700,
                color: isMe ? _kBlueDark : _kMuted,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _avatar(
            initials: _initials(item.name),
            size: 40,
            gradient: _avatarGradient(item.position),
            fontSize: 14.4,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(size: 14.5, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      _mePill(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtPoints(item.points)} pts',
                  style: _sg(size: 12, weight: FontWeight.w700, color: _kMuted, letterSpacing: -0.1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _trendIcon(item),
        ],
      ),
    );
  }
}

class _RankingFullListPage extends StatelessWidget {
  final List<RankingItem> ranking;
  final int? currentUserId;

  const _RankingFullListPage({
    required this.ranking,
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: _shadow(tight: true),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: _kInk, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RANKING',
                        style: _pjs(size: 11, weight: FontWeight.w600, color: _kSoft, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranking da academia',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(size: 20, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.4),
                      ),
                    ],
                  ),
                ),
                _countPill(ranking.length),
              ],
            ),
            const SizedBox(height: 22),
            for (final item in ranking)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RankingRow(item: item, isMe: item.userId == currentUserId),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectorPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectorPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: _pjs(size: 13, weight: FontWeight.w700, color: selected ? Colors.white : _kMuted, letterSpacing: -0.2),
        ),
      ),
    );
  }
}

class _SmallSelectorPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SmallSelectorPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBlue.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? _kBlue.withValues(alpha: 0.30) : Colors.transparent),
          boxShadow: _shadow(tight: true),
        ),
        child: Text(
          label,
          style: _pjs(size: 12, weight: FontWeight.w700, color: selected ? _kBlue : _kMuted),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.wifi_off_rounded,
      title: 'Erro ao carregar',
      subtitle: error,
      color: _kRed,
      action: onRetry,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.emoji_events_outlined,
      title: 'Sem dados neste período',
      subtitle: 'Faça check-ins e treinos para aparecer no ranking.',
      color: _kBlue,
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? action;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(22),
      decoration: _whiteDecoration(22),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: _pjs(size: 16, weight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: action,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(14)),
                child: Text('Tentar novamente', style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _avatar({
  required String initials,
  required double size,
  required List<Color> gradient,
  required double fontSize,
  Border? border,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      shape: BoxShape.circle,
      border: border,
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      textAlign: TextAlign.center,
      style: _pjs(size: fontSize, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
    ),
  );
}

Widget _rankBubble(int rank) {
  return Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_rankLight(rank), _rankBase(rank)],
      ),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      '$rank',
      style: _sg(size: 12, weight: FontWeight.w700, color: _rankText(rank)),
    ),
  );
}

Widget _mePill() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(100)),
    child: Text('VOCÊ', style: _pjs(size: 9.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
  );
}

Widget _countPill(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: _kInk.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(100)),
    child: Text('$count', style: _sg(size: 11, weight: FontWeight.w700, color: _kMuted)),
  );
}

Widget _trendIcon(RankingItem item) {
  final growth = item.growthPct;
  final up = growth == null || growth >= 0;
  final color = up ? _kGreen : _kRed;
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 15),
  );
}

Widget _growthBadge(RankingItem item) {
  final growth = item.growthPct;
  if (growth == null) return const SizedBox.shrink();
  final label = growth == 999 ? 'Novo' : '${growth >= 0 ? '+' : ''}$growth%';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: _kLime, borderRadius: BorderRadius.circular(100)),
    child: Text(label, style: _sg(size: 10.5, weight: FontWeight.w700, color: _kBlueDark, letterSpacing: 0.3)),
  );
}

String _shortName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length <= 1) return name;
  return '${parts.first} ${parts.last}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

String _fmtPoints(int points) => NumberFormat.decimalPattern('pt_BR').format(points);

List<Color> _avatarGradient(int seed) {
  return switch (seed) {
    1 => const [Color(0xFFE5A300), Color(0xFFFFC65C)],
    2 => const [Color(0xFFE859A1), Color(0xFFFF8FBC)],
    3 => const [Color(0xFF2F6FED), Color(0xFF4A8CFF)],
    4 => const [Color(0xFF0E9F8B), Color(0xFF4FD1B8)],
    5 => const [Color(0xFF7A5AE0), Color(0xFFA98EFF)],
    _ => const [Color(0xFFFF7A5C), Color(0xFFFFAB8A)],
  };
}

Color _rankLight(int rank) {
  return switch (rank) {
    1 => const Color(0xFFFFE9A1),
    2 => const Color(0xFFEFF3F8),
    _ => const Color(0xFFF8E3D0),
  };
}

Color _rankBase(int rank) {
  return switch (rank) {
    1 => const Color(0xFFFFD56B),
    2 => const Color(0xFFD6DDE7),
    _ => const Color(0xFFECC7A6),
  };
}

Color _rankText(int rank) {
  return switch (rank) {
    1 => const Color(0xFF7A4A00),
    2 => const Color(0xFF3D4A5C),
    _ => const Color(0xFF5C3415),
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
