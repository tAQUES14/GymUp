import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../challenges/challenge_api_service.dart';
import '../challenges/challenge_details_page.dart';
import '../checkin/checkin_page.dart';
import '../workouts/models/workout_model.dart';
import '../workouts/models/workout_plan_model.dart';
import '../workouts/workout_api_service.dart';
import '../workouts/workout_plan_api_service.dart';
import '../workouts/workout_plan_utils.dart';
import '../ranking/ranking_api_service.dart';
import '../auth/auth_api_service.dart';
import '../notifications/notification_api_service.dart';
import 'widgets/home_header.dart';
import 'widgets/home_weekly_card.dart';
import 'widgets/home_checkin_button.dart';
import 'widgets/home_stats_grid.dart';
import 'widgets/home_quick_access.dart';
import 'widgets/home_today_activity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DashboardData? _dashboardData;
  ChallengeData? _challengeData;
  WorkoutModel?  _todayWorkout;
  TodayWorkoutPlan? _todayPlan;
  int? _pointsRanking;
  int _unreadNotifications = 0;
  String _avatarUrl = '';
  bool _hasWorkoutAvailable = false;

  bool _isLoading  = true;
  bool _hasError   = false;
  bool _isStarting = false;
  String? _errorMessage;

  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final seq = ++_loadSeq;

    setState(() { _isLoading = true; _hasError = false; _errorMessage = null; });

    try {
      final api     = WorkoutApiService();
      final results = await Future.wait<dynamic>([
        api.getDashboard(),
        api.getWorkouts(),
        ChallengeApiService().getActiveChallenge().catchError((_) => null),
        WorkoutPlanApiService().getTodayWorkout().catchError((_) => null),
        _loadPointsRanking().catchError((_) => null),
        NotificationApiService().unreadCount().catchError((_) => 0),
      ]);

      if (!mounted || seq != _loadSeq) return;

      final data     = results[0] as DashboardData;
      final workouts = results[1] as List<WorkoutModel>;
      final plan     = results[3] as TodayWorkoutPlan?;
      final pointsRanking = results[4] as int?;
      final unreadNotifications = results[5] as int? ?? 0;
      final avatarUrl = await _loadAvatarUrl();

      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _dashboardData = data;
        _todayPlan     = plan;
        _pointsRanking = pointsRanking ?? (data.ranking > 0 ? data.ranking : null);
        _unreadNotifications = unreadNotifications;
        _avatarUrl     = avatarUrl;
        if (plan != null && !plan.isRestDay) {
          _todayWorkout = _workoutFromPlan(plan);
        } else if (plan == null) {
          _todayWorkout = workouts.isNotEmpty ? workouts.first : null;
        } else {
          _todayWorkout = workouts.isNotEmpty ? workouts.first : null;
        }
        _hasWorkoutAvailable =
            workouts.isNotEmpty || (plan != null && !plan.isRestDay && plan.today.exercises.isNotEmpty);
        _challengeData = results[2] as ChallengeData?;
        _isLoading     = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;

      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _hasError = true; _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  WorkoutModel _workoutFromPlan(TodayWorkoutPlan plan) => workoutFromPlan(plan);

  Future<int?> _loadPointsRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;

    final items = await RankingApiService().getRanking(
      period: 'all',
      scope: 'gym',
    );

    for (final item in items) {
      if (item.userId == userId) return item.position;
    }

    return null;
  }

  Future<String> _loadAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var avatarUrl = prefs.getString('user_avatar_url') ?? '';

    try {
      final me = await AuthApiService().getMe();
      avatarUrl = (me['avatar_url'] as String?) ?? '';
      if (avatarUrl.trim().isNotEmpty) {
        await prefs.setString('user_avatar_url', avatarUrl);
      } else {
        await prefs.remove('user_avatar_url');
      }
    } catch (_) {
      // A tela inicial continua funcionando mesmo se /me falhar.
    }

    return avatarUrl;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: GymUpLoading(),
      );
    }

    if (_hasError || _dashboardData == null) {
      return _buildError();
    }

    final data = _dashboardData!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: AppColors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header inline (avatar, saudação, ícones) ──────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 12),
                  child: HomeHeader(
                    nome:            data.name,
                    points:          data.pointsBalance,
                    avatarUrl:       _avatarUrl,
                    hasNotification: _unreadNotifications > 0,
                    notificationCount: _unreadNotifications,
                    onCalendar:      () => Navigator.pushNamed(context, '/history'),
                    onBell:          () async {
                      await Navigator.pushNamed(context, '/notifications');
                      if (mounted) _loadDashboard();
                    },
                  ),
                ),

                const SizedBox(height: 4),

                // ── Card semanal grande ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeWeeklyCard(
                    workoutsDone:   data.onPlanWorkoutsDone,
                    weeklyGoal:     data.weeklyGoal,
                    remainingWorkouts: data.remainingWorkoutsThisWeek,
                    weeklyProgress: data.weeklyProgress,
                    hasCheckedInToday: data.hasCheckedInToday,
                    hasCompletedToday: data.hasCompletedToday,
                    isRestDayToday: _todayPlan?.isRestDay ?? false,
                    onStartTap:     _isStarting
                        ? null
                        : (_todayPlan?.isRestDay ?? false)
                            ? _handleRestDayWorkout
                            : _handleStartWorkout,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Botão check-in ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeCheckinButton(
                    hasCheckedIn: data.hasCheckedInToday,
                    onTap:        _isStarting ? null : _handleCheckinCardTap,
                  ),
                ),

                const SizedBox(height: 22),

                // ── Grid 2×2 de estatísticas ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeStatsGrid(
                    points:     data.pointsBalance,
                    checkins:   data.totalCheckins,
                    streak:     data.streak,
                    bestStreak: data.bestStreak,
                    ranking:    _pointsRanking ?? 0,
                  ),
                ),

                const SizedBox(height: 18),

                // ── Seção "Acesso rápido" ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Acesso rápido', style: AppText.sectionTitle),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeQuickAccess(
                    data:           data,
                    todayWorkout:   _todayWorkout,
                    todayPlan:      _todayPlan,
                    challengeData:  _challengeData,
                    onWorkoutTap:   _isStarting
                        ? null
                        : (_todayPlan?.isRestDay ?? false)
                            ? _handleRestDayWorkout
                            : _handleStartWorkout,
                    onChallengesTap: () {
                      if (_challengeData != null) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChallengeDetailsPage(
                            challenge: _challengeData!,
                          ),
                        )).then((_) => _loadDashboard());
                      } else {
                        Navigator.pushNamed(context, '/challenges');
                      }
                    },
                    onAchievementsTap: () => Navigator.pushNamed(context, '/achievements'),
                    onStoreTap: () => Navigator.pushReplacementNamed(context, '/store'),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Seção "Atividade de hoje" ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeTodayActivity(
                    data:      data,
                    onViewAll: () => Navigator.pushNamed(context, '/history'),
                  ),
                ),

                // Espaço inferior para a bottom nav bar
                const SizedBox(height: 128),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error state
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  child: Icon(Icons.wifi_off_rounded, size: 34, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 20),
                Text('Sem conexão', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  'Não foi possível carregar seus dados.\nVerifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadDashboard,
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Handlers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleStartWorkout() async {
    if (_isStarting) return;
    final data = _dashboardData!;

    if (_todayWorkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum treino cadastrado. Crie um treino na aba Treinos.'),
        ),
      );
      return;
    }

    // Treino em andamento → retomar (mostra info de há quanto tempo)
    if (data.hasActiveSession) {
      final elapsedMin = data.activeSessionElapsedMinutes;
      if (elapsedMin != null && elapsedMin > 0) {
        final label = elapsedMin >= 60
            ? '${elapsedMin ~/ 60}h${elapsedMin % 60 > 0 ? ' ${elapsedMin % 60}min' : ''}'
            : '${elapsedMin}min';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retomando treino (sessao aberta ha $label)'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _pushWorkoutStep();
      return;
    }

    // Já treinou hoje → confirmar extra
    if (data.hasCompletedToday) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Treino extra', style: AppTypography.h3),
          content: Text(
            'Você já concluiu seu treino de hoje.\nDeseja fazer um treino extra? (não contará pontos)',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    // Sem check-in → pedir QR
    if (!data.hasCheckedInToday) {
      Navigator.of(context).pushNamed('/checkin').then((_) => _loadDashboard());
      return;
    }

    // Iniciar treino
    setState(() => _isStarting = true);
    try {
      await WorkoutApiService().startWorkout();
      if (!mounted) return;
      _pushWorkoutStep();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == '401') {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _showNoWorkoutForCheckin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Você ainda não tem treino criado ou indicado no plano. Crie um treino antes de liberar o QR Code.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _handleCheckinCardTap() async {
    if (_isStarting || _dashboardData == null) return;
    final data = _dashboardData!;

    if (!_hasWorkoutAvailable) {
      _showNoWorkoutForCheckin();
      return;
    }

    if (_todayPlan?.isRestDay ?? false) {
      if (data.hasCheckedInToday) {
        await _handleStartWorkout();
      } else {
        await _handleRestDayWorkout();
      }
      return;
    }

    if (data.hasCheckedInToday) {
      await _handleStartWorkout();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed('/checkin').then((_) => _loadDashboard());
  }

  Future<void> _handleRestDayWorkout() async {
    if (!_hasWorkoutAvailable) {
      _showNoWorkoutForCheckin();
      return;
    }

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

    Navigator.of(context)
        .pushNamed(
          '/checkin',
          arguments: const CheckinPageArgs(isRestDayWorkout: true),
        )
        .then((_) => _loadDashboard());
  }

  void _pushWorkoutStep() {
    assert(_todayWorkout!.id > 0, 'BUG: workout com ID inválido.');
    Navigator.of(context)
        .pushNamed('/workout-step', arguments: _todayWorkout)
        .then((_) => _loadDashboard());
  }
}
