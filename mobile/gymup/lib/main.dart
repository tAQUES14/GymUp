import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymup/firebase_options.dart';
import 'package:gymup/core/theme/app_theme.dart';
import 'package:gymup/core/widgets/gymup_loading.dart';

import 'package:gymup/features/auth/auth_service.dart';
import 'package:gymup/features/services/firestore_service.dart';
import 'package:gymup/features/services/points_service.dart';
import 'package:gymup/features/workouts/services/workout_ai_service.dart';
import 'package:gymup/features/workouts/services/weight_service.dart';

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
import 'package:gymup/features/workouts/workout_concept_page.dart';
import 'package:gymup/features/workouts/workout_execution_simple_page.dart';
import 'package:gymup/features/workouts/workout_execution_exercise_page.dart';
import 'package:gymup/features/workouts/models/workout_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<WorkoutAiService>(create: (_) => WorkoutAiService()),
        Provider<WeightService>(create: (_) => WeightService()),
        Provider<PointsService>(create: (_) => PointsService()),
      ],
      child: const GymUpApp(),
    ),
  );
}

class GymUpApp extends StatelessWidget {
  const GymUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYMUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: GymUpLoading()));
          }

          if (snapshot.hasData) {
            return const AppShell();
          }

          return const LoginPage();
        },
      ),
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
        '/workout-detail': (context) => const WorkoutDetailPage(),
        '/workout-step': (context) => const WorkoutStepPage(),
        '/workout-execution': (context) => WorkoutExecutionSimplePage(
          workout: ModalRoute.of(context)?.settings.arguments,
        ),
        '/workout-concept': (context) => const WorkoutConceptPage(),
        '/workout-generated': (context) => const WorkoutGeneratedPage(),
        '/workout-execution-exercise': (context) =>
            WorkoutExecutionExercisePage(
              workout:
                  ModalRoute.of(context)?.settings.arguments as WorkoutModel,
            ),
      },
    );
  }
}
