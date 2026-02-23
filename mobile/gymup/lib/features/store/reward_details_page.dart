import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../services/firestore_service.dart';

class RewardDetailsPage extends StatefulWidget {
  final String? rewardId;
  final Map<String, dynamic>? data;

  const RewardDetailsPage({super.key, this.rewardId, this.data});

  @override
  State<RewardDetailsPage> createState() => _RewardDetailsPageState();
}

class _RewardDetailsPageState extends State<RewardDetailsPage> {
  bool _isLoading = false;

  Future<void> _resgatar() async {
    if (widget.rewardId == null) return;

    setState(() => _isLoading = true);
    try {
      final custo = widget.data?['custo_pontos'] ?? 0;
      await context.read<FirestoreService>().resgatarRecompensa(
        widget.rewardId!,
        custo,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Sucesso!', style: AppTypography.h3),
            content: Text(
              'Recompensa resgatada com sucesso! Retire na recepção.',
              style: AppTypography.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to store
                },
                child: Text(
                  'OK',
                  style: AppTypography.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Scaffold(
        appBar: GymUpAppBar(title: 'Detalhes'),
        body: Center(child: Text('Recompensa não encontrada')),
      );
    }

    final String titulo = widget.data!['titulo'] ?? 'Recompensa';
    final String descricao = widget.data!['descricao'] ?? 'Sem descrição';
    final int custo = widget.data!['custo_pontos'] ?? 0;
    final String? imagemUrl = widget.data!['imagem_url'];

    return Scaffold(
      appBar: const GymUpAppBar(title: 'Detalhes'),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 300,
                    color: Colors.grey[200],
                    child:
                        imagemUrl != null &&
                            imagemUrl.isNotEmpty &&
                            !imagemUrl.contains('placeholder')
                        ? Image.network(
                            imagemUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.card_giftcard,
                              size: 80,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: AppTypography.h2),
                        const SizedBox(height: 8),
                        Text(
                          '$custo pontos',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Descrição', style: AppTypography.h3),
                        const SizedBox(height: 8),
                        Text(
                          descricao,
                          style: AppTypography.bodyLarge.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GymUpButton(
              label: 'RESGATAR AGORA',
              onPressed: _resgatar,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
