import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import 'ranking_api_service.dart';
import 'ranking_periodo.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final _service = RankingApiService();

  RankingPeriodo _periodo = RankingPeriodo.semanal;

  List<RankingItem> _ranking = [];
  int? _currentUserId;
  bool _isLoading = false;
  String? _error;

  /// Referência ao fetch em andamento. Mais robusto que flag booleana:
  /// garante que NENHUM code-path (initState, pull-to-refresh, chip)
  /// consiga disparar um segundo request enquanto outro está em voo.
  Future<void>? _activeFetch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarRanking();
    });
  }

  // ── Carrega o ranking do período atual ─────────────────────────────────────
  Future<void> _carregarRanking() async {
    if (_activeFetch != null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _activeFetch = _executarFetch();
      await _activeFetch;
    } finally {
      _activeFetch = null;
    }
  }

  // ── Troca o período e inicia EXATAMENTE 1 request ─────────────────────────
  void _trocarPeriodo(RankingPeriodo novo) {
    if (_periodo == novo || _activeFetch != null) return;
    setState(() {
      _periodo = novo;
      _isLoading = true;
      _error = null;
    });
    _activeFetch = _executarFetch();
    _activeFetch!.whenComplete(() => _activeFetch = null);
  }

  // ── Parte assíncrona pura: não chama setState no início ───────────────────
  Future<void> _executarFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');

      final items = await _service.getRanking(period: _periodo.param);

      if (mounted) {
        setState(() {
          _ranking = items;
          _isLoading = false;
        });
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
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Ranking'),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _carregarRanking,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDesafioCard(),
                    const SizedBox(height: 16),
                    _buildPeriodoChips(),
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
                  child: Text(
                    'Erro ao carregar ranking.\n$_error',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.error,
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
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma presença registrada\nneste período.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _ranking[index];
                    final isCurrentUser = item.userId == _currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GymUpCard(
                        color: isCurrentUser
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getMedalColor(index),
                              foregroundColor: Colors.white,
                              child: Text(
                                '#${item.position}',
                                style: AppTypography.h3.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (isCurrentUser)
                                    Text(
                                      'Você',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.points} pts',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _ranking.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesafioCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desafio Atual',
                  style: AppTypography.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quem tiver mais pontos no período\nselecionado vence o desafio.',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoChips() {
    return Row(
      children: RankingPeriodo.values.map((periodo) {
        final isSelected = _periodo == periodo;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  periodo.label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              selected: isSelected,
              // _trocarPeriodo ignora o bool do ChoiceChip e usa o enum diretamente,
              // garantindo exatamente 1 setState + 1 request por interação.
              onSelected: (_) => _trocarPeriodo(periodo),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            ),
          ),
        );
      }).toList(),
    );
  }
}
