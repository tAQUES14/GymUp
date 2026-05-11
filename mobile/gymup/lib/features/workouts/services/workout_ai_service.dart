import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_model.dart';
import '../../../core/api/api_service.dart';
import '../../auth/auth_service.dart';

class WorkoutAiService {
  String get baseUrl => ApiService.baseUrl;

  // 🔹 Geração continua local (mock IA)
  Future<WorkoutModel> gerarTreinoIA({
    required String objetivo,
    required String nivel,
    required int tempo,
    required List<String> equipamentos,
    double? pesoAtual,
    double? pesoPretendido,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    return WorkoutModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: 'Treino Personalizado IA',
      description:
          'Objetivo: $objetivo | Nível: $nivel | Peso: ${pesoAtual ?? "N/A"}kg → ${pesoPretendido ?? "N/A"}kg',
      duration: tempo,
      level: nivel,
      exercises: [],
      isGenerated: true,
    );
  }

  // 🔹 Salvar no Laravel
  Future<void> saveWorkout(BuildContext context, WorkoutModel workout) async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/custom-workouts"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(workout.toMap()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar treino");
    }
  }

  // 🔹 Buscar treinos personalizados
  Future<List<WorkoutModel>> getCustomWorkouts(BuildContext context) async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/custom-workouts"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar treinos");
    }

    final List data = jsonDecode(response.body);

    return data.map((item) => WorkoutModel.fromMap(item)).toList();
  }

  // 🔹 Deletar treino inteiro
  Future<void> deleteWorkout(BuildContext context, int workoutId) async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/custom-workouts/$workoutId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar treino");
    }
  }
}
