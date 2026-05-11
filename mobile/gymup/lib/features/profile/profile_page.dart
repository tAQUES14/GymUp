import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_service.dart';
import '../goals/goal_api_service.dart';
import '../goals/create_goal_page.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGreen    = Color(0xFF10B981);
const _kAmber    = Color(0xFFF59E0B);

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
  double?               _currentWeight;
  late Future<void>     _profileFuture;

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _nomeController     = TextEditingController();
    _telefoneController = TextEditingController();
    _idadeController    = TextEditingController();
    _pesoController     = TextEditingController();
    _alturaController   = TextEditingController();
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

    final logWeight     = weightHistory.isNotEmpty ? weightHistory.first.weight : null;
    final profileWeight = data['weight'] != null
        ? double.tryParse(data['weight'].toString())
        : null;
    final resolvedWeight = logWeight ?? profileWeight ?? goal?.startWeight;

    final profileHeight = data['height'] != null
        ? double.tryParse(data['height'].toString())
        : null;
    final resolvedHeight = profileHeight ?? goal?.height;

    final gymName = gym?['name'] as String?;
    if (gymName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gym_name', gymName);
    }

    setState(() {
      _userData                = data;
      _goalData                = goal;
      _currentWeight           = resolvedWeight;
      _nomeController.text     = data['name'] ?? '';
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
        'name':   _nomeController.text.trim(),
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
          SnackBar(
            content: const Text('Perfil atualizado com sucesso!'),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } catch (e) {
      developer.log('SaveProfile error: $e', name: 'ProfilePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'Meu Perfil',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded,
                          color: AppColors.error, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar perfil',
                        style: AppTypography.h3, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(err,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() { _profileFuture = _loadProfile(); }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kBlue, _kBlueDark]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Tentar novamente',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_userData == null) {
            return const Center(child: Text('Dados não disponíveis'));
          }

          final pontos        = (_userData!['points_balance'] as num?)?.toInt() ?? 0;
          final totalCheckins = (_userData!['total_checkins'] as num?)?.toInt() ?? 0;
          final streak        = (_userData!['current_streak'] as num?)?.toInt() ?? 0;
          final email         = _userData!['email'] as String? ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar + Name hero ─────────────────────────────────
                  _buildAvatarHero(email),
                  const SizedBox(height: 20),

                  // ── Stats strip ────────────────────────────────────────
                  _buildStatsStrip(pontos, totalCheckins, streak),
                  const SizedBox(height: 24),

                  // ── Dados pessoais card ────────────────────────────────
                  _buildDadosPessoaisCard(),
                  const SizedBox(height: 16),

                  // ── Save button (only in edit mode) ────────────────────
                  if (_isEditing) ...[
                    _buildGradientButton(
                      label: 'Salvar Alterações',
                      loading: _isLoading,
                      onTap: _saveProfile,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Meta section ───────────────────────────────────────
                  _buildGoalsSection(),
                  const SizedBox(height: 32),

                  // ── Sign out ───────────────────────────────────────────
                  _buildSignOutButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Avatar Hero ─────────────────────────────────────────────────────────────

  Widget _buildAvatarHero(String email) {
    final name    = _nomeController.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : null;

    return Row(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: initial != null
                ? Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800))
                : const Icon(Icons.person_rounded,
                    color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : 'Usuário',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(email,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Membro ativo',
                    style: TextStyle(
                        color: _kGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Strip ─────────────────────────────────────────────────────────────

  Widget _buildStatsStrip(int pontos, int checkins, int streak) {
    return Row(
      children: [
        Expanded(child: _statCard('$pontos', 'Pontos', Icons.stars_rounded, _kBlue)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('$checkins', 'Check-ins', Icons.qr_code_scanner_rounded, const Color(0xFF6366F1))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('$streak', 'Sequência', Icons.local_fire_department_rounded, _kAmber)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Dados Pessoais Card ─────────────────────────────────────────────────────

  Widget _buildDadosPessoaisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: _kBlue, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Dados Pessoais',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _nomeController,
            label: 'Nome completo',
            icon: Icons.badge_outlined,
            readOnly: !_isEditing,
            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _pesoController,
                  label: 'Peso (kg)',
                  icon: Icons.monitor_weight_outlined,
                  readOnly: !_isEditing,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _alturaController,
                  label: 'Altura (cm)',
                  icon: Icons.height_rounded,
                  readOnly: !_isEditing,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _academiaController,
            label: 'Academia',
            icon: Icons.store_outlined,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18,
            color: readOnly ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── Gradient button ─────────────────────────────────────────────────────────

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: loading ? 0.7 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  Widget _buildSignOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthService>().signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('Sair da conta',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── Goals Section ───────────────────────────────────────────────────────────

  Widget _buildGoalsSection() {
    if (_goalData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag_outlined, color: _kBlue, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Metas',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            Text('Você ainda não definiu uma meta pessoal.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final peso   = double.tryParse(_pesoController.text);
                final altura = double.tryParse(_alturaController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGoalPage(
                      initialWeight: peso,
                      initialHeight: altura,
                    ),
                  ),
                ).then((_) => setState(() { _profileFuture = _loadProfile(); }));
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kBlue, _kBlueDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Definir meta',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final goal      = _goalData!;
    final nowWeight = _currentWeight ?? goal.startWeight;
    final faltam    = (goal.targetWeight - nowWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, color: _kGreen, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Meta atual',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(goal.goalTypeLabel,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(
            '${nowWeight.toStringAsFixed(1)} kg → ${goal.targetWeight.toStringAsFixed(1)} kg  '
            '(faltam ${faltam.toStringAsFixed(1)} kg)',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/goals')
                .then((_) => setState(() { _profileFuture = _loadProfile(); })),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: _kBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: _kBlue, size: 16),
                    SizedBox(width: 6),
                    Text('Ver progresso',
                        style: TextStyle(
                            color: _kBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
