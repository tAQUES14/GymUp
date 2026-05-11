import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import 'ranking_api_service.dart';
import 'ranking_periodo.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGold     = Color(0xFFF59E0B);
const _kSilver   = Color(0xFF94A3B8);
const _kBronze   = Color(0xFFCD7F32);

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final _service    = RankingApiService();
  RankingPeriodo _periodo = RankingPeriodo.all;
  RankingEscopo  _escopo  = RankingEscopo.gym;
  List<RankingItem> _ranking = [];
  int?  _currentUserId;
  bool  _hasChain  = false;
  bool  _isLoading = false;
  String? _error;
  Future<void>? _activeFetch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarInfoRede();
        _carregarRanking();
      }
    });
  }

  /// Determina se o usuário pertence a uma rede de academias.
  /// Lê do SharedPreferences (populado pelo getMe); se ausente, chama o
  /// endpoint /me uma vez para preencher o cache.
  Future<void> _carregarInfoRede() async {
    final prefs = await SharedPreferences.getInstance();
    var chainId = prefs.getInt('gym_chain_id');

    if (chainId == null && prefs.getString('auth_token') != null) {
      try {
        await AuthApiService().getMe(); // popula 'gym_chain_id' no SharedPreferences
        chainId = prefs.getInt('gym_chain_id');
      } catch (_) {}
    }

    if (mounted) setState(() => _hasChain = chainId != null);
  }

  Future<void> _carregarRanking() async {
    if (_activeFetch != null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      _activeFetch = _executarFetch();
      await _activeFetch;
    } finally {
      _activeFetch = null;
    }
  }

  void _trocarPeriodo(RankingPeriodo novo) {
    if (_periodo == novo || _activeFetch != null) return;
    setState(() { _periodo = novo; _isLoading = true; _error = null; });
    _activeFetch = _executarFetch();
    _activeFetch!.whenComplete(() => _activeFetch = null);
  }

  void _trocarEscopo(RankingEscopo novo) {
    if (_escopo == novo || _activeFetch != null) return;
    setState(() { _escopo = novo; _isLoading = true; _error = null; });
    _activeFetch = _executarFetch();
    _activeFetch!.whenComplete(() => _activeFetch = null);
  }

  Future<void> _executarFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final items = await _service.getRanking(
        period: _periodo.param,
        scope:  _escopo.param,
      );
      if (mounted) {
        setState(() { _ranking = items; _isLoading = false; });
      }
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '401' && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar ranking: $msg')),
        );
        setState(() { _error = msg; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'Ranking',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarRanking,
        color: _kBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 16),
                    if (_hasChain) ...[
                      _buildScopeSelector(),
                      const SizedBox(height: 10),
                    ],
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(child: GymUpLoading())
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wifi_off_rounded,
                              color: AppColors.error, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar',
                            style: AppTypography.bodyLarge
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _carregarRanking,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _kBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Tentar novamente',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_ranking.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.emoji_events_outlined,
                            size: 32,
                            color: _kBlue.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text('Sem dados neste período',
                          style: AppTypography.bodyLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Faça check-ins para aparecer no ranking!',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else ...[
              if (_ranking.length >= 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _Podium(
                      top3: _ranking.take(3).toList(),
                      currentUserId: _currentUserId,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final offset = _ranking.length >= 2 ? 3 : 0;
                      final item = _ranking[offset + index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RankingListItem(
                          item: item,
                          isMe: item.userId == _currentUserId,
                        ),
                      );
                    },
                    childCount: _ranking.length >= 2
                        ? (_ranking.length - 3).clamp(0, _ranking.length)
                        : _ranking.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Competição ${_periodo.label}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _escopo == RankingEscopo.chain
                      ? 'Alunos de toda a sua rede.'
                      : 'Acumule pontos com check-ins e treinos.',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: RankingEscopo.values.map((escopo) {
          final isSelected = _escopo == escopo;
          return Expanded(
            child: GestureDetector(
              onTap: () => _trocarEscopo(escopo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: _kBlue.withValues(alpha: 0.20),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )]
                      : null,
                ),
                child: Text(
                  escopo.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _kBlue,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: RankingPeriodo.values.map((periodo) {
          final isSelected = _periodo == periodo;
          return Expanded(
            child: GestureDetector(
              onTap: () => _trocarPeriodo(periodo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: _kBlue.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )]
                      : null,
                ),
                child: Text(
                  periodo.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pódio top 3 ───────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<RankingItem> top3;
  final int? currentUserId;
  const _Podium({required this.top3, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final first  = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third  = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second != null
              ? _PodiumSlot(
                  item: second,
                  color: _kSilver,
                  podiumHeight: 72,
                  avatarSize: 44,
                  isMe: second.userId == currentUserId,
                )
              : const SizedBox(),
        ),
        Expanded(
          child: _PodiumSlot(
            item: first,
            color: _kGold,
            podiumHeight: 100,
            avatarSize: 52,
            isMe: first.userId == currentUserId,
            showCrown: true,
          ),
        ),
        Expanded(
          child: third != null
              ? _PodiumSlot(
                  item: third,
                  color: _kBronze,
                  podiumHeight: 52,
                  avatarSize: 40,
                  isMe: third.userId == currentUserId,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final RankingItem item;
  final Color color;
  final double podiumHeight;
  final double avatarSize;
  final bool isMe;
  final bool showCrown;

  const _PodiumSlot({
    required this.item,
    required this.color,
    required this.podiumHeight,
    required this.avatarSize,
    required this.isMe,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial   = item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';
    final firstName = item.name.split(' ').first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown)
          const Text('👑', style: TextStyle(fontSize: 18))
        else
          const SizedBox(height: 24),
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isMe
                ? Border.all(color: _kBlue, width: 2.5)
                : Border.all(
                    color: color.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: avatarSize * 0.40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          firstName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
            color: isMe ? _kBlue : const Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.gymName != null) ...[
          const SizedBox(height: 1),
          Text(
            item.gymName!,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 2),
        Text(
          '${item.points} pts',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        if (item.growthPct != null) ...[
          const SizedBox(height: 2),
          Text(
            item.growthPct == 999 ? 'Novo' : _growthLabel(item.growthPct!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _growthColor(item.growthPct!),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Stack(
            children: [
              Container(
                height: podiumHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  border: Border(
                    left: BorderSide(color: color.withValues(alpha: 0.25)),
                    right: BorderSide(color: color.withValues(alpha: 0.25)),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: color,
                ),
              ),
              SizedBox(
                height: podiumHeight,
                child: Center(
                  child: Text(
                    '#${item.position}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
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

// ── Item de lista (4º em diante) ─────────────────────────────────────────────

class _RankingListItem extends StatelessWidget {
  final RankingItem item;
  final bool isMe;
  const _RankingListItem({required this.item, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final initial = item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _kBlue.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? _kBlue.withValues(alpha: 0.25)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${item.position}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isMe ? _kBlue : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isMe ? _kBlue : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    color: isMe ? _kBlue : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.gymName != null)
                  Text(
                    item.gymName!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (isMe)
                  const Text('Você',
                      style: TextStyle(fontSize: 11, color: _kBlue)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.points} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                  ),
                ),
              ),
              if (item.growthPct != null) ...[
                const SizedBox(height: 3),
                Text(
                  item.growthPct == 999 ? 'Novo' : _growthLabel(item.growthPct!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _growthColor(item.growthPct!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers de crescimento ────────────────────────────────────────────────────

String _growthLabel(int pct) => pct >= 0 ? '+$pct%' : '$pct%';

Color _growthColor(int pct) {
  if (pct > 0) return const Color(0xFF10B981);  // emerald
  if (pct < 0) return const Color(0xFFEF4444);  // red
  return const Color(0xFF94A3B8);                // slate
}
