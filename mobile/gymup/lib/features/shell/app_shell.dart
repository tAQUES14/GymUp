import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../ranking/ranking_page.dart';
import '../store/store_page.dart';
import '../workouts/workouts_page.dart';
import 'global_app_header.dart';

const _kBlue = Color(0xFF2F6FED);
const _kInactive = Color(0xFF5B6472);

class _Tab {
  final String icon;
  final String label;

  const _Tab({required this.icon, required this.label});
}

const _tabs = [
  _Tab(icon: 'assets/icons/nav/home.svg', label: 'Início'),
  _Tab(icon: 'assets/icons/nav/workouts.svg', label: 'Treinos'),
  _Tab(icon: 'assets/icons/nav/store.svg', label: 'Loja'),
  _Tab(icon: 'assets/icons/nav/ranking.svg', label: 'Ranking'),
  _Tab(icon: 'assets/icons/nav/profile.svg', label: 'Perfil'),
];

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _kTabKey = 'last_tab_index';

  late int _currentIndex;
  late final List<Widget?> _pages = List<Widget?>.filled(_tabs.length, null);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    _pages[_currentIndex] = _buildPage(_currentIndex);
  }

  Widget _buildPage(int index) => switch (index) {
    0 => const HomePage(),
    1 => const WorkoutsPage(),
    2 => const StorePage(),
    3 => const RankingPage(),
    4 => const ProfilePage(),
    _ => const SizedBox.shrink(),
  };

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      _pages[index] ??= _buildPage(index);
    });
    SharedPreferences.getInstance().then((p) => p.setInt(_kTabKey, index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Column(
              children: [
                GlobalAppHeader(currentIndex: _currentIndex),
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    minimum: const EdgeInsets.only(top: 8),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List<Widget>.generate(
                        _pages.length,
                        (index) => _pages[index] ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NavDock(
              child: _CustomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDock extends StatelessWidget {
  final Widget child;

  const _NavDock({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.0, 0.42],
                  ).createShader(bounds);
                },
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFFF2F4F7).withValues(alpha: 0.98),
                            const Color(0xFFF2F4F7).withValues(alpha: 0.82),
                            const Color(0xFFF2F4F7).withValues(alpha: 0.34),
                            const Color(0xFFF2F4F7).withValues(alpha: 0.00),
                          ],
                          stops: const [0.0, 0.48, 0.78, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x0F0E1116)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0F172A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x190F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                return _NavItem(
                  tab: _tabs[i],
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.98), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final item = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 14 : 4,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? _kBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: selected ? const Color(0x512F6FED) : Colors.transparent,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: SvgPicture.asset(
                  widget.tab.icon,
                  key: ValueKey('${widget.tab.label}-$selected'),
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    selected
                        ? Colors.white
                        : _kInactive.withValues(alpha: 0.85),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Row(
                        children: [
                          const SizedBox(width: 7),
                          Text(
                            widget.tab.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );

    final animatedItem = AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: item,
    );

    return selected ? animatedItem : Expanded(child: animatedItem);
  }
}
