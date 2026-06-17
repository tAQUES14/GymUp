import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gymup_loading.dart';
import 'notification_api_service.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kLine = Color(0x140E1116);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationApiService();
  final _scroll = ScrollController();

  final List<AppNotification> _items = [];
  int _unreadCount = 0;
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _lastPage = 1;
    }

    setState(() {
      _loading = !refresh;
      _error = null;
    });

    try {
      final result = await _service.getNotifications(page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.notifications);
        _unreadCount = result.unreadCount;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _loading = false;
      });
    } catch (e) {
      if (e.toString().contains('401') && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _maybeLoadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 220) return;

    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = await _service.getNotifications(page: next);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.notifications);
        _unreadCount = result.unreadCount;
        _page = result.currentPage;
        _lastPage = result.lastPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (!item.isUnread) return;
    setState(() {
      final index = _items.indexWhere((n) => n.id == item.id);
      if (index >= 0) {
        _items[index] = AppNotification(
          id: item.id,
          title: item.title,
          message: item.message,
          createdAt: item.createdAt,
          readAt: DateTime.now(),
        );
      }
      _unreadCount = (_unreadCount - 1).clamp(0, 999).toInt();
    });

    try {
      await _service.markRead(item.id);
    } catch (_) {
      // Mantem a UI fluida; o refresh corrige qualquer divergencia.
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0 || _markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          final item = _items[i];
          _items[i] = AppNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            createdAt: item.createdAt,
            readAt: item.readAt ?? DateTime.now(),
          );
        }
        _unreadCount = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const GymUpLoading()
            : RefreshIndicator(
                color: AppColors.blue,
                onRefresh: () => _load(refresh: true),
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(onMarkAll: _markAllRead, unreadCount: _unreadCount, marking: _markingAll)),
                    if (_error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Erro ao carregar',
                          message: _error!,
                          actionLabel: 'Tentar novamente',
                          onAction: _load,
                        ),
                      )
                    else if (_items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateCard(
                          icon: Icons.notifications_none_rounded,
                          title: 'Nada por aqui',
                          message: 'Suas conquistas, resgates e avisos importantes aparecem aqui.',
                          actionLabel: 'Atualizar',
                          onAction: () => _load(refresh: true),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        sliver: SliverList.separated(
                          itemCount: _items.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue)),
                              );
                            }
                            final item = _items[index];
                            return _NotificationTile(item: item, onTap: () => _markRead(item));
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;
  final bool marking;
  final VoidCallback onMarkAll;

  const _Header({
    required this.unreadCount,
    required this.marking,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
              const Spacer(),
              if (unreadCount > 0)
                TextButton(
                  onPressed: marking ? null : onMarkAll,
                  child: Text(
                    marking ? 'Marcando...' : 'Marcar todas',
                    style: AppText.pjs(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificacoes',
                      style: AppText.pjs(
                        size: 30,
                        weight: FontWeight.w800,
                        color: _kInk,
                        height: 1,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unreadCount > 0
                          ? '$unreadCount nova${unreadCount == 1 ? '' : 's'} notificacao${unreadCount == 1 ? '' : 'es'}'
                          : 'Tudo lido por enquanto.',
                      style: AppText.pjs(size: 14, weight: FontWeight.w600, color: _kMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = item.isUnread;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: unread ? AppColors.blue.withValues(alpha: 0.24) : _kLine),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: unread ? 0.08 : 0.05),
              blurRadius: unread ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: unread ? AppColors.blueTint : const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _iconFor(item.title),
                size: 19,
                color: unread ? AppColors.blue : _kSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.pjs(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: _kInk,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.message,
                    style: AppText.pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _relativeTime(item.createdAt),
                    style: AppText.pjs(size: 11, weight: FontWeight.w700, color: _kSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String title) {
    final value = title.toLowerCase();
    if (value.contains('resgate') || value.contains('recompensa')) return Icons.redeem_outlined;
    if (value.contains('desafio')) return Icons.emoji_events_outlined;
    if (value.contains('conquista')) return Icons.star_outline_rounded;
    if (value.contains('treino')) return Icons.fitness_center_rounded;
    return Icons.notifications_none_rounded;
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atras';
    if (diff.inHours < 24) return '${diff.inHours} h atras';
    if (diff.inDays < 7) return '${diff.inDays} d atras';
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: AppColors.blue),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppText.pjs(size: 18, weight: FontWeight.w800, color: _kInk)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: AppText.pjs(size: 13, weight: FontWeight.w500, color: _kMuted, height: 1.35)),
              const SizedBox(height: 18),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: _kInk, size: 22),
      ),
    );
  }
}
