import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

const _kBlue = Color(0xFF2563EB);

const _sectionTitles = [
  null,
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
    // Home, workouts, store, ranking, and profile render their headers inside the page.
    if (currentIndex == 0 || currentIndex == 1 || currentIndex == 2 || currentIndex == 3 || currentIndex == 4) {
      return const SizedBox.shrink();
    }

    final title = _sectionTitles[currentIndex];

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
              child: _SectionHeader(key: ValueKey(title), title: title!),
            ),
          ),
        ),
      ),
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
