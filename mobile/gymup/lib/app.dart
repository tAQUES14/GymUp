import 'package:flutter/material.dart';
import 'package:gymup/core/theme/app_theme.dart';
import 'package:gymup/features/auth/auth_gate.dart';

import 'package:gymup/features/auth/login_page.dart';
import 'package:gymup/features/auth/register_page.dart';
import 'package:gymup/features/shell/app_shell.dart';
import 'package:gymup/features/checkin/checkin_page.dart';
import 'package:gymup/features/ranking/ranking_page.dart';
import 'package:gymup/features/store/store_page.dart';
import 'package:gymup/features/store/reward_details_page.dart';
import 'package:gymup/features/profile/profile_page.dart';
import 'package:gymup/features/workouts/workouts_page.dart';
import 'package:gymup/features/workouts/workout_detail_page.dart';
import 'package:gymup/features/workouts/workout_step_page.dart';
import 'package:gymup/features/workouts/workout_generated_page.dart';
import 'package:gymup/features/workouts/workout_concept_page.dart';
import 'package:gymup/features/workouts/workout_execution_simple_page.dart';
import 'package:gymup/features/workouts/workout_execution_exercise_page.dart';
import 'package:gymup/features/workouts/models/workout_model.dart';
import 'package:gymup/features/personals/personals_page.dart';
import 'package:gymup/features/progress/progress_page.dart';
import 'package:gymup/features/history/history_page.dart';

class GymUpApp extends StatelessWidget {
  const GymUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYMUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const AppShell(),
        '/checkin': (context) => const CheckinPage(),
        '/ranking': (context) => const RankingPage(),
        '/store': (context) => const StorePage(),
        '/profile': (context) => const ProfilePage(),
        '/rewardDetails': (context) => const RewardDetailsPage(),
        '/workouts': (context) => const WorkoutsPage(),
        '/personals': (context) => const PersonalsPage(),
        '/progress': (context) => const ProgressPage(),
        '/history': (context) => const HistoryPage(),
        '/workout-generated': (context) => const WorkoutGeneratedPage(),
        '/workout-concept': (context) => const WorkoutConceptPage(),
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

        if (settings.name == '/workout-execution') {
          final workout = settings.arguments as WorkoutModel;
          return MaterialPageRoute(
            builder: (_) =>
                WorkoutExecutionSimplePage(workout: workout),
          );
        }

        if (settings.name == '/workout-execution-exercise') {
          final workout = settings.arguments as WorkoutModel;
          return MaterialPageRoute(
            builder: (_) =>
                WorkoutExecutionExercisePage(workout: workout),
          );
        }

        return null;
      },
    );
  }
}