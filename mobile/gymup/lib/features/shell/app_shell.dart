import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_page.dart';
import '../workouts/workouts_page.dart';
import '../store/store_page.dart';
import '../ranking/ranking_page.dart';
import '../profile/profile_page.dart';
import 'global_app_header.dart';

const _kBlue     = Color(0xFF2563EB);
const _kInactive = Color(0xFF94A3B8); // slate-400 — mais suave que gray

// ─── Tab definitions ──────────────────────────────────────────────────────────

class _Tab {
  final IconData icon;
  final IconData selectedIcon;
  final String   label;

  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// Ícones modernos: trophy p/ ranking, account_circle p/ perfil,
// storefront p/ loja, bolt p/ energia de treino
const _tabs = [
  _Tab(
    icon:         Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label:        'Home',
  ),
  _Tab(
    icon:         Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center_rounded,
    label:        'Treinos',
  ),
  _Tab(
    icon:         Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
    label:        'Loja',
  ),
  _Tab(
    icon:         Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events_rounded,
    label:        'Ranking',
  ),
  _Tab(
    icon:         Icons.account_circle_outlined,
    selectedIcon: Icons.account_circle_rounded,
    label:        'Perfil',
  ),
];

// ─── Shell ────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WorkoutsPage(),
    StorePage(),
    RankingPage(),
    ProfilePage(),
  ];

  static const _kTabKey = 'last_tab_index';

  @override
  void initState() {
    super.initState();
    _restoreTab();
  }

  Future<void> _restoreTab() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kTabKey) ?? 0;
    if (mounted && saved != _currentIndex) {
      setState(() => _currentIndex = saved.clamp(0, _pages.length - 1));
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    SharedPreferences.getInstance().then((p) => p.setInt(_kTabKey, index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          GlobalAppHeader(currentIndex: _currentIndex),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: _CustomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─── Custom bottom nav ────────────────────────────────────────────────────────

class _CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Borda top: linha sutil de separação
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF2F7), width: 0.8),
        ),
        // Duas camadas de sombra: ambiente + direcional — sensação de elevação real
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          // 72px: mais alto, mais premium (Strava/Revolut usam 72-80dp)
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_tabs.length, (i) {
              return _NavItem(
                tab:      _tabs[i],
                selected: currentIndex == i,
                onTap:    () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Item com pill premium ────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final _Tab         tab;
  final bool         selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 260),
    );
    // Spring bounce: sobe rápido, desce suave — sensação elástica
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0),  weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _ctrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    // Área de toque: GestureDetector opaque garante ≥ 48dp em toda a região
    return GestureDetector(
      onTap:    widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          // Espaçamento externo: 8px horizontal dá respiro entre itens
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve:    Curves.easeInOut,
            padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              // Pill azul ativo — AnimatedContainer lerpa cor E sombra suavemente
              color: selected ? _kBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // Glow azul: dá profundidade e "levanta" o pill da navbar
                  color: selected
                      ? _kBlue.withValues(alpha: 0.32)
                      : Colors.transparent,
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Ícone 24px — mais visível, mais sólido
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Icon(
                    selected ? widget.tab.selectedIcon : widget.tab.icon,
                    key:   ValueKey(selected),
                    color: selected ? Colors.white : _kInactive,
                    size:  24, // era 22 — agora mais sólido
                  ),
                ),

                const SizedBox(height: 3),

                // Label: inactive mais discreto (w400), ativo bold branco
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color:         selected ? Colors.white : _kInactive,
                    fontSize:      11, // mínimo Caption per typography guide
                    fontWeight:    selected ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: selected ? 0.2 : 0.0,
                    height:        1.0,
                  ),
                  child: Text(widget.tab.label),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
