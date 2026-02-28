import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_app_bar.dart';
import '../../core/widgets/gymup_button.dart';
import '../../core/widgets/gymup_card.dart';
import '../../core/widgets/gymup_text_field.dart';
import '../../core/widgets/gymup_loading.dart';
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

  Map<String, dynamic>? _userData;
  late Future<void> _profileFuture;

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _telefoneController = TextEditingController();
    _idadeController = TextEditingController();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _academiaController = TextEditingController();
    _profileFuture = _loadProfile();
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

  Future<void> _loadProfile() async {
    developer.log('GET ${ApiService.baseUrl}/profile', name: 'ProfilePage');

    final response = await _api.get('/profile');

    developer.log(
      'ProfilePage response: status=${response.statusCode} body=${response.body}',
      name: 'ProfilePage',
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final gym = data['gym'] as Map<String, dynamic>?;

    setState(() {
      _userData = data;
      _nomeController.text = data['name'] ?? '';
      _telefoneController.text = data['phone'] ?? '';
      _idadeController.text = '';
      _pesoController.text = (data['weight'] ?? '').toString();
      _alturaController.text = (data['height'] ?? '').toString();
      _academiaController.text = gym?['name'] ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _api.put('/me', {
        'name': _nomeController.text.trim(),
        'weight': double.tryParse(_pesoController.text.trim()),
        'height': double.tryParse(_alturaController.text.trim()),
      });

      developer.log(
        'SaveProfile response: status=${response.statusCode} body=${response.body}',
        name: 'ProfilePage',
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      developer.log('SaveProfile error: $e', name: 'ProfilePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GymUpAppBar(
        title: 'Meu Perfil',
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            developer.log('ProfilePage FutureBuilder error: $err', name: 'ProfilePage');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar perfil',
                      style: AppTypography.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err,
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.red.shade300),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GymUpButton(
                      label: 'Tentar novamente',
                      onPressed: () => setState(() {
                        _profileFuture = _loadProfile();
                      }),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_userData == null) {
            return const Center(child: Text("Dados não disponíveis"));
          }

          final pontos = (_userData!['points_balance'] as num?)?.toInt() ?? 0;
          final totalCheckins = (_userData!['total_checkins'] as num?)?.toInt() ?? 0;
          final streak = (_userData!['current_streak'] as num?)?.toInt() ?? 0;
          final email = _userData!['email'] as String? ?? '';

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
                    Text(_nomeController.text, style: AppTypography.h2),
                    Text(email, style: AppTypography.bodyMedium),
                    const SizedBox(height: 24),
                    _buildStatsCard(pontos, totalCheckins, streak),
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
                          validator: (v) =>
                              v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Peso (kg)',
                          controller: _pesoController,
                          readOnly: !_isEditing,
                        ),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Altura (m)',
                          controller: _alturaController,
                          readOnly: !_isEditing,
                        ),
                        const SizedBox(height: 16),
                        GymUpTextField(
                          label: 'Academia',
                          controller: _academiaController,
                          readOnly: true,
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
                    isSecondary: true,
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

  Widget _buildStatsCard(int pontos, int totalCheckins, int streak) {
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
        const SizedBox(width: 12),
        Expanded(
          child: GymUpCard(
            child: Column(
              children: [
                Text('$totalCheckins', style: AppTypography.h1),
                Text('Check-ins', style: AppTypography.caption),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GymUpCard(
            child: Column(
              children: [
                Text('$streak', style: AppTypography.h1),
                Text('Sequência', style: AppTypography.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
