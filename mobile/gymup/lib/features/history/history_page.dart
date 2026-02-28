import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse("http://127.0.0.1:8000/api/points/history"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao carregar histórico");
    }

    final data = jsonDecode(response.body);

    // ⚠️ Ajuste aqui se sua API retornar estrutura diferente
    final List<dynamic> items = data is List ? data : data["data"];

    return items.map<Map<String, dynamic>>((item) {
      return {
        "title": item["title"] ?? "Movimentação",
        "points": item["points"] ?? 0,
        "date": DateTime.parse(item["created_at"]),
        "isPositive": (item["points"] ?? 0) >= 0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Histórico de Pontos'),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar histórico.',
                style: AppTypography.bodyMedium,
              ),
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(
              child: Text(
                'Nenhum histórico encontrado.',
                style: AppTypography.bodyMedium,
              ),
            );
          }

          // Ordenar por data desc
          history.sort(
            (a, b) =>
                (b["date"] as DateTime).compareTo(a["date"] as DateTime),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final date = item['date'] as DateTime;
              final formattedDate =
                  DateFormat('dd/MM/yyyy HH:mm').format(date);
              final isPositive = item['isPositive'] as bool;
              final points = item['points'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GymUpCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.check_circle
                              : Icons.shopping_bag,
                          color: isPositive
                              ? AppColors.accent
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isPositive ? '+$points' : '-$points',
                        style: AppTypography.h3.copyWith(
                          color: isPositive
                              ? AppColors.accent
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}