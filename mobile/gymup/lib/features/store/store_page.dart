import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';
import 'reward_details_page.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  final List<Map<String, dynamic>> mockRewards = const [
    {
      'id': 'mock_1',
      'titulo': 'Camiseta GymUp',
      'custo_pontos': 500,
      'descricao':
          'Camiseta dry-fit oficial da academia. Disponível em vários tamanhos.',
      'imagem_url':
          'https://via.placeholder.com/150/6C63FF/FFFFFF?text=Camiseta',
    },
    {
      'id': 'mock_2',
      'titulo': 'Squeeze 500ml',
      'custo_pontos': 300,
      'descricao': 'Garrafa de água resistente e estilosa para seus treinos.',
      'imagem_url':
          'https://via.placeholder.com/150/00C853/FFFFFF?text=Squeeze',
    },
    {
      'id': 'mock_3',
      'titulo': 'Desconto 10%',
      'custo_pontos': 1000,
      'descricao': '10% de desconto na próxima mensalidade.',
      'imagem_url':
          'https://via.placeholder.com/150/FFA000/FFFFFF?text=Desconto',
    },
    {
      'id': 'mock_4',
      'titulo': 'Personal (1h)',
      'custo_pontos': 2000,
      'descricao': 'Uma hora de aula exclusiva com um de nossos personais.',
      'imagem_url':
          'https://via.placeholder.com/150/D32F2F/FFFFFF?text=Personal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Loja de Recompensas'),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getRecompensasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          var docs = snapshot.data?.docs ?? [];

          // Use mock data if list is empty
          final List<Map<String, dynamic>> rewards = docs.isNotEmpty
              ? docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return data;
                }).toList()
              : mockRewards;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final data = rewards[index];
              return _buildRewardCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, Map<String, dynamic> data) {
    final String id = data['id'];
    final String titulo = data['titulo'] ?? 'Recompensa';
    final int custo = data['custo_pontos'] ?? 0;
    final String? imagemUrl = data['imagem_url'];

    return GymUpCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RewardDetailsPage(rewardId: id, data: data),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child:
                  imagemUrl != null &&
                      imagemUrl.isNotEmpty &&
                      !imagemUrl.contains('placeholder')
                  ? Image.network(
                      imagemUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image, size: 50, color: Colors.grey),
                    )
                  : Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: 40,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$custo pts',
                  style: AppTypography.h3.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
