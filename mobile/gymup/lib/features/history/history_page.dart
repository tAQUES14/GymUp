import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final response = await ApiService().get('/points/history?per_page=50');

    if (response.statusCode == 401) {
      throw Exception('401');
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar histórico');
    }

    final body = jsonDecode(response.body);
    final List<dynamic> items = body is List ? body : (body['data'] as List<dynamic>? ?? []);

    return items.map<Map<String, dynamic>>((item) {
      final bool isEarn = (item['type'] as String?) == 'earn';
      return {
        'title': item['description'] as String? ?? 'Movimentação',
        'points': (item['points'] as num?)?.toInt() ?? 0,
        'date': DateTime.parse(item['created_at'] as String),
        'isPositive': isEarn,
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
            final err = snapshot.error.toString();
            if (err.contains('401')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/login');
              });
              return const SizedBox.shrink();
            }
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