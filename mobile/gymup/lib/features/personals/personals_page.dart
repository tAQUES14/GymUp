import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_button.dart';

class PersonalsPage extends StatelessWidget {
  const PersonalsPage({super.key});

  final List<Map<String, String>> personals = const [
    {
      'name': 'Ana Silva',
      'specialty': 'Hipertrofia e Emagrecimento',
      'description': 'Especialista em transformação corporal com foco em saúde e bem-estar. 5 anos de experiência.',
    },
    {
      'name': 'João Pereira',
      'specialty': 'Performance e Atletismo',
      'description': 'Treinamento voltado para atletas de alto rendimento e preparação física específica.',
    },
    {
      'name': 'Carlos Souza',
      'specialty': 'Iniciantes e Reabilitação',
      'description': 'Foco em correção postural, fortalecimento e introdução à musculação.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Personais'),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: personals.length,
        itemBuilder: (context, index) {
          final personal = personals[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GymUpCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          personal['name']![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personal['name']!,
                              style: AppTypography.h3,
                            ),
                            Text(
                              personal['specialty']!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    personal['description']!,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  GymUpButton(
                    label: 'Quero saber mais',
                    isSecondary: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de contato em breve!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
