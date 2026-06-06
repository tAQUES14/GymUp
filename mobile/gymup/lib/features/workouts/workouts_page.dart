import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_api_service.dart';
import '../checkin/checkin_page.dart';
import 'models/workout_model.dart';
import 'models/workout_plan_model.dart';
import 'workout_api_service.dart';
import 'workout_plan_api_service.dart';
import 'workout_plan_utils.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  List<WorkoutModel> _workouts = [];
  TodayWorkoutPlan? _todayPlan;
  String _userName = '';
  bool _isLoading = true;
  bool _hasError = false;

  WorkoutModel? get _todayWorkout {
    if (_todayPlan != null && !_todayPlan!.isRestDay) {
      return workoutFromPlan(_todayPlan!);
    }
    if (_todayPlan != null && _todayPlan!.isRestDay) {
      return null;
    }
    return _workouts.isNotEmpty ? _workouts.first : null;
  }

  List<WorkoutModel> get _displayWorkouts {
    final today = _todayWorkout;
    if (today == null) return _workouts;

    final exists = _workouts.any((w) => _sameWorkout(w, today));
    return exists ? _workouts : [today, ..._workouts];
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      var name = prefs.getString('user_name') ?? '';

      final results = await Future.wait<dynamic>([
        WorkoutApiService().getWorkouts(),
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
      ]);

      if (name.isEmpty) {
        try {
          final me = await AuthApiService().getMe();
          name = me['name'] as String? ?? '';
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _userName = name;
        _workouts = results[0] as List<WorkoutModel>;
        _todayPlan = results[1] as TodayWorkoutPlan?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const GymUpLoading()
          : _hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final todayWorkout = _todayWorkout;
    final workouts = _displayWorkouts;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.blue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _WorkoutsHeader(
                      userName: _userName,
                      onCalendar: () => Navigator.pushNamed(context, '/history'),
                      onStats: () => Navigator.pushNamed(context, '/progress'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TodayWorkoutHero(
                      workout: todayWorkout,
                      plan: _todayPlan,
                      onStart: (_todayPlan?.isRestDay ?? false)
                          ? _openRestDayCheckin
                          : todayWorkout == null
                              ? null
                              : () => _openWorkout(todayWorkout),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: _WorkoutsSectionHeader(
                      count: workouts.length,
                      onCreate: _openCreateWorkout,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (workouts.isEmpty)
                          _EmptyWorkoutCard(onCreate: _openCreateWorkout)
                        else
                          ...workouts.map(
                            (workout) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _WorkoutListCard(
                                workout: workout,
                                isToday: todayWorkout != null &&
                                    _sameWorkout(workout, todayWorkout),
                                onTap: () => _openWorkout(workout),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        _AddWorkoutCard(onTap: _openCreateWorkout),
                      ],
                    ),
                  ),
                  const SizedBox(height: 128),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorkout(WorkoutModel workout) {
    Navigator.pushNamed(context, '/workout-detail', arguments: workout)
        .then((_) => _loadAll());
  }

  Future<void> _openRestDayCheckin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Treino livre', style: AppTypography.h3),
        content: Text(
          'Hoje voce nao tem treino obrigatorio. Seu streak esta protegido. Se quiser treinar, leia o QR Code e conclua um treino valido para ganhar pontos.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Voltar',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ler QR Code'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.pushNamed(
      context,
      '/checkin',
      arguments: const CheckinPageArgs(isRestDayWorkout: true),
    ).then((_) => _loadAll());
  }

  void _openCreateWorkout() {
    Navigator.pushNamed(context, '/workout-generated').then((_) => _loadAll());
  }

  bool _sameWorkout(WorkoutModel a, WorkoutModel b) {
    if (a.id > 0 && b.id > 0 && a.id == b.id) return true;
    return a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
  }

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 34,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text('Sem conexao', style: AppTypography.h3),
              const SizedBox(height: 8),
              Text(
                'Nao foi possivel carregar os treinos.\nVerifique sua conexao.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutsHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onCalendar;
  final VoidCallback? onStats;

  const _WorkoutsHeader({
    required this.userName,
    this.onCalendar,
    this.onStats,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'M';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              initial,
              textAlign: TextAlign.center,
              style: AppText.pjs(
                size: 17,
                weight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
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
                'TREINOS',
                style: AppText.pjs(
                  size: 11,
                  weight: FontWeight.w600,
                  color: AppColors.inkLight,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Meus Treinos',
                style: AppText.pjs(
                  size: 22,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        _CircleHeaderButton(
          onTap: onCalendar,
          child: const Icon(
            Icons.calendar_month_outlined,
            size: 22,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        _CircleHeaderButton(
          onTap: onStats,
          child: const Icon(
            Icons.bar_chart_rounded,
            size: 22,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleHeaderButton({required this.child, this.onTap});

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

class _TodayWorkoutHero extends StatelessWidget {
  final WorkoutModel? workout;
  final TodayWorkoutPlan? plan;
  final VoidCallback? onStart;

  const _TodayWorkoutHero({
    required this.workout,
    required this.plan,
    this.onStart,
  });

  bool get _isRestDay => plan?.isRestDay ?? false;

  @override
  Widget build(BuildContext context) {
    final title = _heroTitle;
    final meta = _heroMeta;

    return Container(
      constraints: const BoxConstraints(minHeight: 207),
      padding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.gradientWeekCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.weekCard,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(label: _isRestDay ? 'DIA DE DESCANSO' : 'TREINO DE HOJE'),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.pjs(
                  size: 38,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.4,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              _HeroMetaRow(items: meta),
              const SizedBox(height: 24),
              _HeroStartButton(
                label: _isRestDay ? 'Treinar mesmo assim' : 'Iniciar treino',
                enabled: onStart != null,
                onTap: onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _heroTitle {
    if (_isRestDay) return 'Dia de descanso';
    if (workout != null && workout!.name.trim().isNotEmpty) return workout!.name;
    return 'Sem treino';
  }

  List<_HeroMetaItem> get _heroMeta {
    if (_isRestDay) {
      final planName = plan?.planName.trim();
      return [
        _HeroMetaItem(Icons.self_improvement_rounded, 'Streak protegido'),
        _HeroMetaItem(Icons.event_available_rounded,
            planName == null || planName.isEmpty ? 'Plano ativo' : planName),
      ];
    }

    if (workout == null) {
      return [
        _HeroMetaItem(Icons.add_rounded, 'Crie seu treino'),
      ];
    }

    return [
      _HeroMetaItem(Icons.schedule_rounded, '${workout!.duration ?? 0} min'),
      _HeroMetaItem(Icons.bar_chart_rounded, workout!.level ?? 'Personalizado'),
      _HeroMetaItem(Icons.list_rounded, '${workout!.exercises.length} ex.'),
    ];
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 11, color: AppColors.lime),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.pjs(
              size: 10.5,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaItem {
  final IconData icon;
  final String label;

  const _HeroMetaItem(this.icon, this.label);
}

class _HeroMetaRow extends StatelessWidget {
  final List<_HeroMetaItem> items;

  const _HeroMetaRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i].icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                items[i].label,
                style: AppText.pjs(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (i != items.length - 1)
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ],
    );
  }
}

class _HeroStartButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _HeroStartButton({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.82,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x280F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                enabled ? Icons.play_arrow_rounded : Icons.bedtime_rounded,
                size: 16,
                color: AppColors.blueDark,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.pjs(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.blueDark,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutsSectionHeader extends StatelessWidget {
  final int count;
  final VoidCallback onCreate;

  const _WorkoutsSectionHeader({
    required this.count,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Meus Treinos',
          style: AppText.pjs(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: AppText.sg(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onCreate,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 14, color: AppColors.blue),
                const SizedBox(width: 5),
                Text(
                  'Criar',
                  textAlign: TextAlign.center,
                  style: AppText.pjs(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutListCard extends StatelessWidget {
  final WorkoutModel workout;
  final bool isToday;
  final VoidCallback onTap;

  const _WorkoutListCard({
    required this.workout,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.multiline_chart_rounded,
                size: 26,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          workout.name,
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
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        const _TodayBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _workoutMeta(workout),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pjs(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'HOJE',
        style: AppText.pjs(
          size: 9.5,
          weight: FontWeight.w800,
          color: AppColors.lime,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AddWorkoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWorkoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 24,
                color: AppColors.inkLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adicionar mais um treino',
                    style: AppText.pjs(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Monte uma divisao ABC, push/pull ou personalize',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pjs(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
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

class _EmptyWorkoutCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyWorkoutCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _AddWorkoutCard(onTap: onCreate),
    );
  }
}

String _workoutMeta(WorkoutModel workout) {
  final level = workout.level ?? 'Personalizado';
  final duration = '${workout.duration ?? 0} min';
  final exercises = '${workout.exercises.length} ex.';
  return '$level  -  $duration  -  $exercises';
}
