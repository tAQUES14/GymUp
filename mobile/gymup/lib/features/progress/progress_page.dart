import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_service.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<Map<String, dynamic>> _fetchDashboard() async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao carregar progresso");
    }

    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Meu Progresso'),
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar progresso"));
          }

          final data = snapshot.data ?? {};

          final int totalPresencas = data["total_checkins"] ?? 0;
          final int totalTreinos = data["total_workouts"] ?? 0;

          final List<int> weeklyPoints =
              (data["weekly_points"] as List<dynamic>? ?? [0, 0, 0, 0])
                  .map((e) => e as int)
                  .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(totalPresencas, totalTreinos),
                const SizedBox(height: 32),
                Text(
                  'Pontos nas últimas 4 semanas',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 16),
                _buildChart(weeklyPoints),
                const SizedBox(height: 32),
                _buildAchievementCard(totalTreinos),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int presencas, int treinos) {
    return Row(
      children: [
        Expanded(
          child: GymUpCard(
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  '$presencas',
                  style: AppTypography.h1.copyWith(color: Colors.white),
                ),
                Text(
                  'Presenças',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GymUpCard(
            child: Column(
              children: [
                Text(
                  '$treinos',
                  style: AppTypography.h1.copyWith(color: AppColors.primary),
                ),
                Text(
                  'Treinos',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<int> data) {
    final int max =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);

    return GymUpCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final int value = data[index];
            final double heightFactor =
                max == 0 ? 0.0 : (value / max).toDouble();

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heightFactor),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, val, child) {
                    return Container(
                      width: 30,
                      height: 150 * val,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem ${index + 1}',
                  style: AppTypography.caption,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(int totalTreinos) {
    final double progresso =
        ((totalTreinos % 20) / 20).toDouble();

    return GymUpCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Text(
            'Próxima Conquista',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete 20 treinos para ganhar o badge "Dedicado"!',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.warning),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalTreinos % 20} / 20',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}