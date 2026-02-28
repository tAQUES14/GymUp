import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../../auth/auth_service.dart';

class WeightService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<void> saveWeight(
    BuildContext context,
    String exerciseId,
    double weight,
    int reps,
    String note,
  ) async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/exercises/$exerciseId/weight"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "weight": weight,
        "reps": reps,
        "note": note,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erro ao salvar carga");
    }
  }

  Future<Map<String, dynamic>?> getLastWeight(
    BuildContext context,
    String exerciseId,
  ) async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/exercises/$exerciseId/weight/last"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);

    // Esperado retorno:
    // {
    //   "weight": 40,
    //   "reps": 12,
    //   "note": "Fácil",
    //   "created_at": "..."
    // }

    return data;
  }
}