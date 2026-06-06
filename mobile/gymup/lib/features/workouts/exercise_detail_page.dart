import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/workout_model.dart';
import 'widgets/exercise_image_widget.dart';

class ExerciseDetailPage extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(exercise);
    final cautions = _cautionsFor(exercise);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: _ExerciseHeader(title: exercise.name),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GifHero(exercise: exercise),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _ExerciseIntro(exercise: exercise),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _ExecutionCard(steps: steps),
              ),
              if (cautions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _CautionCard(cautions: cautions),
                ),
              const SizedBox(height: 126),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BackToWorkoutDock(
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }

  static List<String> _stepsFor(ExerciseModel exercise) {
    if (exercise.executionSteps.isNotEmpty) return exercise.executionSteps;
    return const [
      'Ajuste a postura inicial e mantenha o tronco firme.',
      'Execute o movimento com controle, sem usar impulso.',
      'Volte a posicao inicial mantendo a tensao no musculo alvo.',
    ];
  }

  static List<String> _cautionsFor(ExerciseModel exercise) {
    if (exercise.commonMistakes.isNotEmpty) return exercise.commonMistakes;
    if (exercise.tips.isNotEmpty) return exercise.tips.take(2).toList();
    return const [
      'Mantenha a postura neutra durante todo o movimento.',
      'Evite acelerar a repeticao quando estiver cansado.',
    ];
  }
}

class _ExerciseHeader extends StatelessWidget {
  final String title;

  const _ExerciseHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.pjs(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          onTap: () {},
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 24,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.navBtn,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GifHero extends StatelessWidget {
  final ExerciseModel exercise;

  const _GifHero({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 262,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.32, -0.16),
          end: Alignment(0.68, 1.16),
          colors: [AppColors.blueTint, Color(0xFFF0FFD9)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x0A0E1116)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x232F6FED),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExerciseGifPanel(
              exercise: exercise,
              height: 262,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseIntro extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExerciseIntro({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center_rounded, size: 11, color: AppColors.blueDark),
              const SizedBox(width: 5),
              Text(
                _badgeLabel(exercise),
                style: AppText.pjs(
                  size: 10,
                  weight: FontWeight.w800,
                  color: AppColors.blueDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          exercise.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.pjs(
            size: 26,
            weight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.05,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _description(exercise),
          style: AppText.pjs(
            size: 13.5,
            weight: FontWeight.w500,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  static String _badgeLabel(ExerciseModel exercise) {
    final muscle = exercise.muscleGroup.trim().isEmpty
        ? 'EXERCICIO'
        : exercise.muscleGroup.trim().toUpperCase();
    return '$muscle - COMPOSTO';
  }

  static String _description(ExerciseModel exercise) {
    final desc = exercise.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;

    final muscle = exercise.muscleGroup.trim().toLowerCase();
    if (muscle.isEmpty) {
      return 'Exercicio do treino com foco em controle, tecnica e boa execucao.';
    }
    return 'Exercicio focado em $muscle, com controle de movimento e boa tecnica.';
  }
}

class _ExecutionCard extends StatelessWidget {
  final List<String> steps;

  const _ExecutionCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.format_list_numbered_rounded,
                    size: 17, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Text(
                'Como executar',
                style: AppText.pjs(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 14),
              child: _StepRow(index: i + 1, text: steps[i]),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;

  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$index',
              style: AppText.sg(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blueDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              text,
              style: AppText.pjs(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CautionCard extends StatelessWidget {
  final List<String> cautions;

  const _CautionCard({required this.cautions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.17, -0.53),
          end: Alignment(0.83, 1.53),
          colors: [AppColors.yellowTint, AppColors.orangeTint],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 17, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUIDADOS',
                  style: AppText.pjs(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.orangeDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cautions.join(' '),
                  style: AppText.pjs(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackToWorkoutDock extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToWorkoutDock({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00F3F5F9),
            Color(0xD8F3F5F9),
            Color(0xFFF3F5F9),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimaryDark,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.buttonBlue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    size: 22, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Voltar ao treino',
                  textAlign: TextAlign.center,
                  style: AppText.pjs(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
