import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:gymup/core/theme/app_theme.dart';
import 'package:gymup/features/auth/auth_gate.dart';

import 'package:gymup/features/auth/login_page.dart';
import 'package:gymup/features/auth/register_page.dart';
import 'package:gymup/features/auth/google_invite_page.dart';
import 'package:gymup/features/auth/forgot_password_page.dart';
import 'package:gymup/features/auth/reset_password_page.dart';
import 'package:gymup/features/onboarding/onboarding_page.dart';
import 'package:gymup/features/shell/app_shell.dart';
import 'package:gymup/features/checkin/checkin_page.dart';
import 'package:gymup/features/store/reward_details_page.dart';
import 'package:gymup/features/workouts/workout_detail_page.dart';
import 'package:gymup/features/workouts/workout_step_page.dart';
import 'package:gymup/features/workouts/workout_generated_page.dart';
import 'package:gymup/features/workouts/workout_concept_page.dart';
import 'package:gymup/features/workouts/workout_execution_exercise_page.dart';
import 'package:gymup/features/workouts/models/workout_model.dart';
import 'package:gymup/features/personals/personals_page.dart';
import 'package:gymup/features/progress/progress_page.dart';
import 'package:gymup/features/history/history_page.dart';
import 'package:gymup/features/challenges/challenges_page.dart';
import 'package:gymup/features/challenges/my_achievements_page.dart';
import 'package:gymup/features/goals/create_goal_page.dart';
import 'package:gymup/features/goals/goal_summary_page.dart';
import 'package:gymup/features/notifications/notifications_page.dart';
import 'package:gymup/features/settings/settings_page.dart';

class GymUpApp extends StatefulWidget {
  const GymUpApp({super.key});

  @override
  State<GymUpApp> createState() => _GymUpAppState();
}

class _GymUpAppState extends State<GymUpApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // ── Deep link setup ───────────────────────────────────────────────────────

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Link inicial: app aberto a partir de um link com o app fechado.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (_) {}

    // Links recebidos com o app em background/foreground.
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  /// Interpreta URIs:
  ///   https://gymupapp.com.br/reset-password?token=TOKEN&email=EMAIL
  ///   gymup://reset-password?token=TOKEN&email=EMAIL
  void _handleDeepLink(Uri uri) {
    final isHttpResetPath = (uri.host == 'gymupapp.com.br' ||
            uri.host == 'www.gymupapp.com.br' ||
            uri.host == 'gymup.app' ||
            uri.host == 'localhost') &&
        uri.path == '/reset-password';
    final isSchemeReset =
        uri.scheme == 'gymup' && uri.host == 'reset-password';
    final isSchemeLogin = uri.scheme == 'gymup' && uri.host == 'login';
    final isHttpLoginPath = (uri.host == 'gymupapp.com.br' ||
            uri.host == 'www.gymupapp.com.br' ||
            uri.host == 'gymup.app' ||
            uri.host == 'localhost') &&
        uri.path == '/login';

    if (isSchemeLogin || isHttpLoginPath) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    if (!isHttpResetPath && !isSchemeReset) return;

    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];
    if (token == null || email == null) return;

    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/reset-password',
      // Mantém o login na pilha para o botão "Voltar ao login" funcionar.
      (route) => route.settings.name == '/login',
      arguments: <String, String>{'token': token, 'email': email},
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYMUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      home: const AuthGate(),

      routes: {
        '/login':            (context) => const LoginPage(),
        '/onboarding':       (context) => const OnboardingPage(),
        '/register':         (context) => const RegisterPage(),
        '/google-invite':    (context) => const GoogleInvitePage(),
        '/forgot-password':  (context) => const ForgotPasswordPage(),
        '/reset-password':   (context) => const ResetPasswordPage(),
        '/home':             (context) => const AppShell(initialIndex: 0),
        '/checkin':          (context) => const CheckinPage(),
        '/ranking':          (context) => const AppShell(initialIndex: 3),
        '/store':            (context) => const AppShell(initialIndex: 2),
        '/profile':          (context) => const AppShell(initialIndex: 4),
        '/rewardDetails':    (context) => const RewardDetailsPage(),
        '/workouts':         (context) => const AppShell(initialIndex: 1),
        '/personals':        (context) => const PersonalsPage(),
        '/progress':         (context) => const ProgressPage(),
        '/history':          (context) => const HistoryPage(),
        '/challenges':       (context) => const ChallengesPage(),
        '/achievements':     (context) => const MyAchievementsPage(),
        '/goals/create':     (context) => const CreateGoalPage(),
        '/goals':            (context) => const GoalSummaryPage(),
        '/notifications':    (context) => const NotificationsPage(),
        '/settings':         (context) => const SettingsPage(),
        '/workout-generated':(context) => const WorkoutGeneratedPage(),
        '/workout-concept':  (context) => const WorkoutConceptPage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/workout-detail') {
          final workout = settings.arguments as WorkoutModel;
          return MaterialPageRoute(
            builder: (_) => WorkoutDetailPage(workout: workout),
          );
        }
        if (settings.name == '/workout-step') {
          final workout = settings.arguments as WorkoutModel;
          return MaterialPageRoute(
            builder: (_) => WorkoutStepPage(workout: workout),
          );
        }
        if (settings.name == '/workout-execution-exercise') {
          final workout = settings.arguments as WorkoutModel;
          return MaterialPageRoute(
            builder: (_) => WorkoutExecutionExercisePage(workout: workout),
          );
        }
        return null;
      },
    );
  }
}
