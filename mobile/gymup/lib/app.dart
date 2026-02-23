import 'package:flutter/material.dart';
import 'package:gymup/core/theme/app_theme.dart';
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const AppShell(),
        '/checkin': (context) => const CheckinPage(),
        '/ranking': (context) => const RankingPage(),
        '/store': (context) => const StorePage(),
        '/profile': (context) => const ProfilePage(),
        // Reward details will be handled via onGenerateRoute or arguments if needed, 
        // but for now we can keep it simple or add it here if it doesn't take args in constructor
        '/rewardDetails': (context) => const RewardDetailsPage(),
        '/workouts': (context) => const WorkoutsPage(),
        '/personals': (context) => const PersonalsPage(),
        '/progress': (context) => const ProgressPage(),
        '/history': (context) => const HistoryPage(),
        '/workout-detail': (context) => const WorkoutDetailPage(),
        '/workout-step': (context) => const WorkoutStepPage(),
        '/workout-generated': (context) => const WorkoutGeneratedPage(),
      },
    );
  }
}
