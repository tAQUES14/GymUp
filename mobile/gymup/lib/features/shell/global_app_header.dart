import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

const _kBlue = Color(0xFF2563EB);

const _sectionTitles = [
  null, // Home — shows brand logo
  'Meus Treinos',
  'Loja',
  'Ranking',
  'Perfil',
];

class GlobalAppHeader extends StatelessWidget {
  final int currentIndex;

  const GlobalAppHeader({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    final isHome  = currentIndex == 0;
    final title   = _sectionTitles[currentIndex];

    return Container(
      color: _kBlue,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.12),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: isHome
                  ? const _HomeHeader(key: ValueKey('home'))
                  : _SectionHeader(key: ValueKey(title), title: title!),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'GymUp',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.h3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
