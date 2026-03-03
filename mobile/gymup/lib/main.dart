import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymup/app.dart';
import 'package:gymup/features/auth/auth_service.dart';
import 'package:gymup/features/workouts/services/workout_ai_service.dart';
import 'package:gymup/features/services/points_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<WorkoutAiService>(create: (_) => WorkoutAiService()),
Provider<PointsService>(create: (_) => PointsService()),
      ],
      child: const GymUpApp(),
    ),
  );
}
