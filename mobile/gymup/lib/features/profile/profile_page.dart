import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_text_field.dart';
import '../../core/widgets/gymup_loading.dart';
import '../services/firestore_service.dart';
import '../auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _academiaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _telefoneController = TextEditingController();
    _idadeController = TextEditingController();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _academiaController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _academiaController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    if (!_isEditing) { // Only populate if not editing to avoid overwriting user input while typing if stream updates
      _nomeController.text = data['nome'] ?? '';
      _telefoneController.text = data['telefone'] ?? '';
      _idadeController.text = data['idade']?.toString() ?? '';
      _pesoController.text = data['peso']?.toString() ?? '';
      _alturaController.text = data['altura']?.toString() ?? '';
      _academiaController.text = data['academia'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'idade': int.tryParse(_idadeController.text.trim()),
        'peso': double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        'altura': double.tryParse(_alturaController.text.trim().replaceAll(',', '.')),
        'academia': _academiaController.text.trim(),
      };

      await context.read<FirestoreService>().updateAluno(data);

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não logado')),
      );
    }

    return Scaffold(
      appBar: GymUpAppBar(
        title: 'Meu Perfil',
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getAlunoStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          
          // Populate controllers only once or when not editing
          // To handle stream updates properly without resetting user input during edit, 
          // we might need a more complex state management, but for now this is fine.
          // We'll populate only if the controller is empty (first load) or we are not editing.
          if (_nomeController.text.isEmpty && !_isEditing) {
             _populateControllers(data);
          }

          final pontos = data['pontos'] ?? 0;
          final email = data['email'] ?? user.email;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  if (!_isEditing) ...[
                    Text(
                      data['nome'] ?? 'Usuário',
                      style: AppTypography.h2,
                    ),
                    Text(
                      email ?? '',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildStatsCard(pontos),
                    const SizedBox(height: 24),
                  ],
                  
                  GymUpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dados Pessoais', style: AppTypography.h3),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Nome Completo',
                          controller: _nomeController,
                          readOnly: !_isEditing,
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Telefone',
                          controller: _telefoneController,
                          readOnly: !_isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GymUpTextField(
                                label: 'Idade',
                                controller: _idadeController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GymUpTextField(
                                label: 'Peso (kg)',
                                controller: _pesoController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GymUpTextField(
                                label: 'Altura (m)',
                                controller: _alturaController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Academia',
                          controller: _academiaController,
                          readOnly: !_isEditing,
                        ),
                      ],
                    ),
                  ),
                  
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    GymUpButton(
                      label: 'Salvar Alterações',
                      isLoading: _isLoading,
                      onPressed: _saveProfile,
                    ),
                  ],

                  const SizedBox(height: 48),
                  GymUpButton(
                    label: 'SAIR',
                    isSecondary: true, // Or make it red/error style
                    onPressed: () async {
                      await context.read<AuthService>().signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      }
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

  Widget _buildStatsCard(int pontos) {
    return Row(
      children: [
        Expanded(
          child: GymUpCard(
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  '$pontos',
                  style: AppTypography.h1.copyWith(color: Colors.white),
                ),
                Text(
                  'Pontos',
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
                  '12', // Mock data
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
}
