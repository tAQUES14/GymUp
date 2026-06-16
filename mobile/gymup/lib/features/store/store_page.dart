import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import 'redemption_model.dart';
import 'reward_api_service.dart';
import 'reward_details_page.dart';
import 'reward_model.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kLime = Color(0xFFC8F84A);
const _kGreen = Color(0xFF5BA300);
const _kOrange = Color(0xFFFF7A1A);
const _kPurple = Color(0xFF7A5AE0);
const _kRed = Color(0xFFEF4444);

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Reward>? _rewards;
  List<Redemption>? _redemptions;
  final _searchCtrl = TextEditingController();
  int _userPoints = 0;
  bool _isLoading = true;
  String? _error;
  int _tabIndex = 0;
  String _category = 'Todos';
  bool _searchOpen = false;
  String _searchQuery = '';
  String _userName = 'Aluno';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        RewardApiService().getRewards(),
        AuthApiService().getMe(),
        RewardApiService().getMyRedemptions(),
      ]);
      if (!mounted) return;
      final user = results[1] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final avatarUrl = user['avatar_url'] as String? ?? prefs.getString('user_avatar_url') ?? '';
      if (avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar_url', avatarUrl);
      }
      final userName = user['name'] as String? ?? prefs.getString('user_name') ?? _userName;
      setState(() {
        _rewards = results[0] as List<Reward>;
        _userPoints = (user['points_balance'] as num?)?.toInt() ?? 0;
        _redemptions = results[2] as List<Redemption>;
        _userName = userName;
        _avatarUrl = avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = e.toString();
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
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, 112 + bottomInset),
            children: [
              _header(),
              if (_searchOpen) ...[
                const SizedBox(height: 12),
                _searchField(),
              ],
              const SizedBox(height: 18),
              _balanceHero(),
              const SizedBox(height: 18),
              _topTabs(),
              const SizedBox(height: 16),
              if (_isLoading)
                const SizedBox(height: 300, child: GymUpLoading())
              else if (_error != null)
                _errorState()
              else if (_tabIndex == 0)
                _rewardsTab()
              else
                _redemptionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        _userAvatar(name: _userName, imageUrl: _avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOJA',
                style: _pjs(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _kSoft,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Recompensas',
                style: _pjs(
                  size: 22,
                  weight: FontWeight.w700,
                  color: _kInk,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        _circleButton(
          _searchOpen ? Icons.close_rounded : Icons.search_rounded,
          onTap: () {
            setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) {
                _searchCtrl.clear();
                _searchQuery = '';
              }
            });
          },
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      style: _pjs(size: 14, weight: FontWeight.w600, color: _kInk),
      decoration: InputDecoration(
        hintText: 'Buscar recompensa...',
        hintStyle: _pjs(size: 14, weight: FontWeight.w500, color: _kSoft),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kBlue),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x140E1116)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x332F6FED)),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _shadow(),
        ),
        child: Icon(icon, size: 18, color: _kInk),
      ),
    );
  }

  Widget _userAvatar({required String name, required String imageUrl}) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, Color(0xFF4A8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isNotEmpty
          ? Image.network(
              imageUrl.trim(),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              cacheWidth: 120,
              cacheHeight: 120,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Center(child: _avatarInitial(initial)),
            )
          : Center(child: _avatarInitial(initial)),
    );
  }

  Widget _avatarInitial(String initial) {
    return Text(
      initial,
      style: _pjs(
        size: 16.8,
        weight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _balanceHero() {
    return Container(
      height: 242,
      padding: const EdgeInsets.fromLTRB(22, 27, 22, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.08, -0.12),
          end: Alignment(0.92, 1.12),
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
            top: 16,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: Colors.white.withValues(alpha: 0.85), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'SEU SALDO',
                    style: _pjs(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _fmtPoints(_userPoints),
                    style: _sg(
                      size: 56,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 0.95,
                      letterSpacing: -2.5,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'pts',
                    style: _sg(
                      size: 18,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.70),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Use seus pontos para resgatar\nbeneficios na sua academia.',
                style: _pjs(
                  size: 13,
                  weight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.35,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
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
                      decoration: BoxDecoration(
                        color: _kLime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up_rounded, color: _kBlueDark, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Top 3',
                              style: _pjs(size: 12.5, weight: FontWeight.w700, color: Colors.white),
                            ),
                            TextSpan(
                              text: ' da semana · continue treinando\npara desbloquear mais',
                              style: _pjs(size: 12.5, weight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _topTab('Recompensas', 0),
          _topTab('Meus resgates', 1),
        ],
      ),
    );
  }

  Widget _topTab(String text, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
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
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: _pjs(
              size: 13,
              weight: FontWeight.w800,
              color: selected ? Colors.white : _kMuted,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardsTab() {
    final rewards = _filteredRewards();
    if ((_rewards ?? []).isEmpty) return _emptyRewards();
    final featured = rewards.isNotEmpty ? rewards.first : (_rewards ?? []).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryChips(),
        const SizedBox(height: 20),
        _sectionTitle('Destaque da semana'),
        const SizedBox(height: 14),
        _FeaturedRewardCard(
          reward: featured,
          userPoints: _userPoints,
          onReturn: _loadData,
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Text(
              'Disponiveis para resgate',
              style: _pjs(size: 17, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
            ),
            const SizedBox(width: 10),
            _countPill(rewards.length),
            const Spacer(),
            Text(
              'Ver tudo',
              style: _pjs(size: 13, weight: FontWeight.w600, color: _kBlue),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: rewards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (context, index) {
            return _RewardTile(
              reward: rewards[index],
              userPoints: _userPoints,
              onReturn: _loadData,
            );
          },
        ),
      ],
    );
  }

  List<Reward> _filteredRewards() {
    final rewards = _rewards ?? [];
    final byCategory = _category == 'Todos' ? rewards : rewards.where((reward) {
      final category = _rewardCategory(reward).label;
      return category == _category;
    }).toList();
    if (_searchQuery.isEmpty) return byCategory;
    final query = _searchQuery.toLowerCase();
    return byCategory.where((reward) {
      final text = '${reward.name} ${reward.description} ${reward.category ?? ''}'.toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Widget _categoryChips() {
    const items = ['Todos', 'Produtos', 'Descontos', 'Beneficios'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = _category == item;
          return GestureDetector(
            onTap: () => setState(() => _category = item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? _kBlue : Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : _shadow(tight: true),
              ),
              child: Text(
                item,
                style: _pjs(
                  size: 13,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : _kMuted,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _redemptionsTab() {
    final redemptions = [...?_redemptions]
      ..sort((a, b) {
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (a.status != 'pending' && b.status == 'pending') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    if (redemptions.isEmpty) {
      return _emptyCard(
        icon: Icons.receipt_long_rounded,
        title: 'Sem resgates',
        subtitle: 'Voce ainda nao resgatou nenhuma recompensa.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Meus resgates'),
        const SizedBox(height: 14),
        for (final redemption in redemptions) _RedemptionCard(redemption: redemption),
      ],
    );
  }

  Widget _errorState() {
    return _emptyCard(
      icon: Icons.wifi_off_rounded,
      title: 'Erro ao carregar',
      subtitle: _error ?? 'Nao foi possivel carregar a loja.',
      action: GestureDetector(
        onTap: _loadData,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(14)),
          child: Text(
            'Tentar novamente',
            style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _emptyRewards() {
    return _emptyCard(
      icon: Icons.card_giftcard_rounded,
      title: 'Nenhuma recompensa disponivel',
      subtitle: 'Volte mais tarde para ver novos beneficios.',
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: _whiteDecoration(24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: _kBlue, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.35),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: _pjs(size: 17, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
    );
  }

  Widget _countPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: _sg(size: 11, weight: FontWeight.w700, color: _kMuted),
      ),
    );
  }
}

class _FeaturedRewardCard extends StatelessWidget {
  final Reward reward;
  final int userPoints;
  final VoidCallback onReturn;

  const _FeaturedRewardCard({
    required this.reward,
    required this.userPoints,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints >= reward.pointsCost;
    final style = _rewardCategory(reward);

    return GestureDetector(
      onTap: () => _openDetails(context, reward, userPoints, onReturn),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _whiteDecoration(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _RewardArt(
                  reward: reward,
                  style: style,
                  height: 132,
                  iconSize: 56,
                  boxSize: 72,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          'MAIS RESGATADO',
                          style: _pjs(size: 10, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 16, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reward.description.isEmpty ? 'Produto oficial da academia' : reward.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUSTA',
                              style: _pjs(size: 10, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.4),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _fmtPoints(reward.pointsCost),
                                  style: _sg(size: 22, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.5),
                                ),
                                Text(
                                  'pts',
                                  style: _sg(size: 12, weight: FontWeight.w700, color: _kMuted),
                                ),
                                if (canRedeem) _youHavePill(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _RedeemButton(canRedeem: canRedeem, compact: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final Reward reward;
  final int userPoints;
  final VoidCallback onReturn;

  const _RewardTile({
    required this.reward,
    required this.userPoints,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints >= reward.pointsCost;
    final style = _rewardCategory(reward);
    return GestureDetector(
      onTap: () => _openDetails(context, reward, userPoints, onReturn),
      child: Opacity(
        opacity: canRedeem ? 1 : 0.92,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _whiteDecoration(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RewardArt(
                reward: reward,
                style: style,
                height: 100,
                iconSize: 38,
                boxSize: 54,
              ),
              const SizedBox(height: 10),
              _CategoryPill(style: style),
              const SizedBox(height: 6),
              Text(
                reward.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 14, weight: FontWeight.w800, color: _kInk, height: 1.18, letterSpacing: -0.25),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _fmtPoints(reward.pointsCost),
                        style: _sg(size: 15.5, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.3),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'pts',
                        style: _sg(size: 10, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: canRedeem
                          ? const _RedeemButton(canRedeem: true, compact: true)
                          : _MissingPointsPill(missing: reward.pointsCost - userPoints),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardArt extends StatelessWidget {
  final Reward reward;
  final _RewardCategory style;
  final double height;
  final double iconSize;
  final double boxSize;

  const _RewardArt({
    required this.reward,
    required this.style,
    required this.height,
    required this.iconSize,
    required this.boxSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.06, -0.08),
          end: const Alignment(0.94, 1.08),
          colors: [style.bg, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kInk.withValues(alpha: 0.04)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0.06, -0.08),
                    end: const Alignment(0.94, 1.08),
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      style.accent.withValues(alpha: 0.06),
                      style.accent.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -29,
            top: -29,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    style.accent.withValues(alpha: 0.14),
                    style.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (reward.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                reward.imageUrl!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Center(
                  child: _IconProductBox(
                    style: style,
                    size: boxSize,
                    iconSize: iconSize,
                  ),
                ),
              ),
            )
          else
            Center(
              child: _IconProductBox(
                style: style,
                size: boxSize,
                iconSize: iconSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconProductBox extends StatelessWidget {
  final _RewardCategory style;
  final double size;
  final double iconSize;

  const _IconProductBox({
    required this.style,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(style.icon, color: style.accent, size: iconSize),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final _RewardCategory style;

  const _CategoryPill({required this.style});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          style.label.toUpperCase(),
          style: _pjs(size: 9.5, weight: FontWeight.w800, color: style.accent, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

class _RedeemButton extends StatelessWidget {
  final bool canRedeem;
  final bool compact;

  const _RedeemButton({required this.canRedeem, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 7 : 12,
      ),
      decoration: BoxDecoration(
        gradient: canRedeem
            ? const LinearGradient(
                begin: Alignment(0.16, -0.45),
                end: Alignment(0.84, 1.45),
                colors: [_kBlueDark, _kBlue],
              )
            : null,
        color: canRedeem ? null : _kInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 100 : 14),
        boxShadow: canRedeem
            ? [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.32),
                  blurRadius: compact ? 10 : 18,
                  offset: Offset(0, compact ? 4 : 8),
                ),
              ]
            : null,
      ),
      child: Text(
        canRedeem ? 'Resgatar' : 'Bloqueado',
        textAlign: TextAlign.center,
        style: _pjs(
          size: compact ? 11.5 : 13.5,
          weight: FontWeight.w800,
          color: canRedeem ? Colors.white : _kSoft,
          letterSpacing: compact ? -0.1 : -0.2,
        ),
      ),
    );
  }
}

class _MissingPointsPill extends StatelessWidget {
  final int missing;

  const _MissingPointsPill({required this.missing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Faltam ${_fmtPoints(missing)} pontos',
        maxLines: 1,
        style: _pjs(size: 10, weight: FontWeight.w700, color: _kSoft),
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final Redemption redemption;

  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(redemption.createdAt);
    final (label, color) = switch (redemption.status) {
      'approved' => ('Aprovado', _kGreen),
      'rejected' => ('Rejeitado', _kRed),
      _ => ('Aguardando', _kOrange),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _whiteDecoration(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: _kBlue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  redemption.rewardName ?? 'Recompensa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(size: 14, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(date, style: _pjs(size: 11, weight: FontWeight.w500, color: _kSoft)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        label,
                        style: _pjs(size: 10.5, weight: FontWeight.w800, color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-${_fmtPoints(redemption.pointsSpent)} pts',
            style: _sg(size: 13, weight: FontWeight.w700, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _RewardCategory {
  final String label;
  final Color bg;
  final Color accent;
  final IconData icon;

  const _RewardCategory({
    required this.label,
    required this.bg,
    required this.accent,
    required this.icon,
  });
}

_RewardCategory _rewardCategory(Reward reward) {
  final text = '${reward.category ?? ''} ${reward.name} ${reward.description}'.toLowerCase();
  if (text.contains('desconto') || text.contains('mensalidade') || text.contains('cupom')) {
    return const _RewardCategory(
      label: 'Descontos',
      bg: Color(0xFFFFEDDC),
      accent: Color(0xFFB85A00),
      icon: Icons.percent_rounded,
    );
  }
  if (text.contains('benef') ||
      text.contains('spa') ||
      text.contains('pass') ||
      text.contains('avaliacao') ||
      text.contains('aula')) {
    return const _RewardCategory(
      label: 'Beneficios',
      bg: Color(0xFFEFE9FD),
      accent: _kPurple,
      icon: Icons.spa_rounded,
    );
  }
  return const _RewardCategory(
    label: 'Produtos',
    bg: Color(0xFFE7EEFE),
    accent: _kBlueDark,
    icon: Icons.shopping_bag_rounded,
  );
}

void _openDetails(
  BuildContext context,
  Reward reward,
  int userPoints,
  VoidCallback onReturn,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RewardDetailsPage(reward: reward, userPoints: userPoints),
    ),
  ).then((_) => onReturn());
}

Widget _youHavePill() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFEDFBD3),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      'voce tem',
      style: _sg(size: 10, weight: FontWeight.w700, color: _kGreen, letterSpacing: 0.2),
    ),
  );
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
      blurRadius: tight ? 6 : 6,
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

String _fmtPoints(int points) {
  return NumberFormat.decimalPattern('pt_BR').format(points);
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
