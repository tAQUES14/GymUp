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
import '../goals/goal_api_service.dart';
import '../goals/create_goal_page.dart';

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
  GoalData?             _goalData;
  double?               _currentWeight; // peso mais recente (log > perfil > meta)
  late Future<void>     _profileFuture;

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

    final goalService = GoalApiService();
    final results = await Future.wait<dynamic>([
      _api.get('/profile'),
      goalService.getCurrentGoal().catchError((_) => null),
      goalService.getBodyWeightHistory(limit: 1).catchError((_) => <BodyWeightLog>[]),
    ]);

    final response = results[0];
    developer.log(
      'ProfilePage response: status=${response.statusCode} body=${response.body}',
      name: 'ProfilePage',
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data          = jsonDecode(response.body) as Map<String, dynamic>;
    final gym           = data['gym'] as Map<String, dynamic>?;
    final goal          = results[1] as GoalData?;
    final weightHistory = results[2] as List<BodyWeightLog>;

    // Resolve peso atual: log mais recente > peso do perfil > peso inicial da meta
    final logWeight     = weightHistory.isNotEmpty ? weightHistory.first.weight : null;
    final profileWeight = data['weight'] != null
        ? double.tryParse(data['weight'].toString())
        : null;
    final resolvedWeight = logWeight ?? profileWeight ?? goal?.startWeight;

    // Resolve altura (cm): perfil > meta
    final profileHeight = data['height'] != null
        ? double.tryParse(data['height'].toString())
        : null;
    final resolvedHeight = profileHeight ?? goal?.height;

    setState(() {
      _userData            = data;
      _goalData            = goal;
      _currentWeight       = resolvedWeight;
      _nomeController.text = data['name'] ?? '';
      _telefoneController.text = data['phone'] ?? '';
      _idadeController.text    = '';
      _pesoController.text     =
          resolvedWeight != null ? resolvedWeight.toStringAsFixed(1) : '';
      _alturaController.text   =
          resolvedHeight != null ? resolvedHeight.toStringAsFixed(0) : '';
      _academiaController.text = gym?['name'] ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _api.put('/profile', {
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
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
                          label: 'Altura (cm)',
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

                  const SizedBox(height: 24),
                  _buildGoalsSection(),

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

  Widget _buildGoalsSection() {
    if (_goalData == null) {
      // Estado 1: sem meta
      return GymUpCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Metas', style: AppTypography.h3),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Você ainda não definiu uma meta pessoal.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final peso   = double.tryParse(_pesoController.text);
                  final altura = double.tryParse(_alturaController.text);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGoalPage(
                        initialWeight: peso,
                        initialHeight: altura, // perfil e meta ambos em cm
                      ),
                    ),
                  ).then((_) => setState(() { _profileFuture = _loadProfile(); }));
                },
                icon: const Icon(Icons.add),
                label: const Text('Definir meta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Estado 2: com meta
    final goal       = _goalData!;
    final nowWeight  = _currentWeight ?? goal.startWeight;
    final faltam     = (goal.targetWeight - nowWeight).abs();

    return GymUpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Meta atual', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 12),
          Text(goal.goalTypeLabel, style: AppTypography.bodyLarge),
          const SizedBox(height: 4),
          Text(
            '${nowWeight.toStringAsFixed(1)} kg → ${goal.targetWeight.toStringAsFixed(1)} kg  '
            '(faltam ${faltam.toStringAsFixed(1)} kg)',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/goals')
                  .then((_) => setState(() {
                        _profileFuture = _loadProfile();
                      })),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Ver progresso'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
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
