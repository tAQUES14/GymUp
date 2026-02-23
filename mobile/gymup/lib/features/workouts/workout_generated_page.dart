import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../../core/widgets/gymup_text_field.dart';
import 'services/workout_ai_service.dart';

class WorkoutGeneratedPage extends StatefulWidget {
  const WorkoutGeneratedPage({super.key});

  @override
  State<WorkoutGeneratedPage> createState() => _WorkoutGeneratedPageState();
}

class _WorkoutGeneratedPageState extends State<WorkoutGeneratedPage> {
  final _formKey = GlobalKey<FormState>();
  final _objetivoController = TextEditingController();
  final _tempoController = TextEditingController();
  final _pesoAtualController = TextEditingController();
  final _pesoPretendidoController = TextEditingController();
  
  String _nivelSelecionado = 'Iniciante';
  final List<String> _niveis = ['Iniciante', 'Intermediário', 'Avançado'];
  
  bool _isLoading = false;

  @override
  void dispose() {
    _objetivoController.dispose();
    _tempoController.dispose();
    _pesoAtualController.dispose();
    _pesoPretendidoController.dispose();
    super.dispose();
  }

  Future<void> _gerarTreino() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = Provider.of<WorkoutAiService>(context, listen: false);
      
      final workout = await aiService.gerarTreinoIA(
        objetivo: _objetivoController.text,
        nivel: _nivelSelecionado,
        tempo: int.tryParse(_tempoController.text) ?? 45,
        equipamentos: [],
        pesoAtual: double.tryParse(_pesoAtualController.text),
        pesoPretendido: double.tryParse(_pesoPretendidoController.text),
      );

      await aiService.saveWorkout(workout);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/workout-detail',
          arguments: workout,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar treino: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymUpAppBar(title: 'Gerar Treino com IA'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Diga-nos o que você precisa',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 8),
              Text(
                'Nossa IA irá criar um treino personalizado para você em segundos.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              GymUpTextField(
                label: 'Qual seu objetivo?',
                controller: _objetivoController,
                hintText: 'Ex: Hipertrofia, Emagrecimento, Resistência',
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: GymUpTextField(
                      label: 'Peso Atual (kg)',
                      controller: _pesoAtualController,
                      keyboardType: TextInputType.number,
                      hintText: 'Ex: 70',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GymUpTextField(
                      label: 'Meta (kg)',
                      controller: _pesoPretendidoController,
                      keyboardType: TextInputType.number,
                      hintText: 'Ex: 75',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GymUpTextField(
                label: 'Tempo disponível (minutos)',
                controller: _tempoController,
                keyboardType: TextInputType.number,
                hintText: 'Ex: 45',
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _nivelSelecionado,
                decoration: InputDecoration(
                  labelText: 'Nível de Experiência',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _niveis.map((nivel) {
                  return DropdownMenuItem(
                    value: nivel,
                    child: Text(nivel),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _nivelSelecionado = value!;
                  });
                },
              ),
              
              const SizedBox(height: 48),
              
              GymUpButton(
                label: 'GERAR TREINO',
                isLoading: _isLoading,
                onPressed: _gerarTreino,
                icon: Icons.auto_awesome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
