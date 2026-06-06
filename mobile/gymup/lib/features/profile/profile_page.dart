import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_service.dart';
import '../../core/widgets/gymup_loading.dart';
import '../auth/auth_service.dart';
import '../goals/create_goal_page.dart';
import '../goals/goal_api_service.dart';

const _kBg = Color(0xFFF3F5F9);
const _kInk = Color(0xFF0E1116);
const _kMuted = Color(0xFF5B6472);
const _kSoft = Color(0xFF9AA3B0);
const _kBlue = Color(0xFF2F6FED);
const _kBlue2 = Color(0xFF4A8CFF);
const _kBlueSoft = Color(0xFFE7EEFE);
const _kLimeSoft = Color(0xFFEDFBD3);
const _kGreen = Color(0xFF5BA300);
const _kAmberSoft = Color(0xFFFFEDDC);
const _kAmber = Color(0xFFFF8A1F);
const _kRed = Color(0xFFD14343);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _pesoController;
  late final TextEditingController _alturaController;
  late final TextEditingController _academiaController;

  late Future<void> _profileFuture;
  Map<String, dynamic>? _userData;
  GoalData? _goalData;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _academiaController = TextEditingController();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
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
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final gym = data['gym'] as Map<String, dynamic>?;
    final goal = results[1] as GoalData?;
    final weightHistory = results[2] as List<BodyWeightLog>;

    final logWeight = weightHistory.isNotEmpty ? weightHistory.first.weight : null;
    final profileWeight = data['weight'] != null ? double.tryParse(data['weight'].toString()) : null;
    final resolvedWeight = logWeight ?? profileWeight ?? goal?.startWeight;
    final profileHeight = data['height'] != null ? double.tryParse(data['height'].toString()) : null;
    final resolvedHeight = profileHeight ?? goal?.height;
    final gymName = gym?['name'] as String?;

    if (gymName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gym_name', gymName);
    }

    if (!mounted) return;
    setState(() {
      _userData = data;
      _goalData = goal;
      _nomeController.text = data['name'] as String? ?? '';
      _pesoController.text = resolvedWeight != null ? resolvedWeight.toStringAsFixed(1) : '';
      _alturaController.text = resolvedHeight != null ? resolvedHeight.toStringAsFixed(0) : '';
      _academiaController.text = gymName ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final response = await _api.put('/profile', {
        'name': _nomeController.text.trim(),
        'weight': double.tryParse(_pesoController.text.trim()),
        'height': double.tryParse(_alturaController.text.trim()),
      });

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _profileFuture = _loadProfile();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil atualizado com sucesso!'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      developer.log('SaveProfile error: $e', name: 'ProfilePage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<void>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GymUpLoading();
          }

          if (snapshot.hasError) {
            return _ProfileError(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _profileFuture = _loadProfile()),
            );
          }

          if (_userData == null) {
            return _ProfileError(
              message: 'Dados n\u00E3o dispon\u00EDveis.',
              onRetry: () => setState(() => _profileFuture = _loadProfile()),
            );
          }

          final data = _userData!;
          final points = (data['points_balance'] as num?)?.toInt() ?? 0;
          final checkins = (data['total_checkins'] as num?)?.toInt() ?? 0;
          final streak = (data['current_streak'] as num?)?.toInt() ?? 0;
          final email = data['email'] as String? ?? '';
          final bottomInset = MediaQuery.of(context).padding.bottom;

          return Form(
            key: _formKey,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 126 + bottomInset),
              children: [
                _ProfileHeader(
                  editing: _isEditing,
                  onEditToggle: () => setState(() => _isEditing = !_isEditing),
                ),
                const SizedBox(height: 16),
                _ProfileHero(
                  name: _displayName,
                  email: email,
                  gymName: _academiaController.text,
                  avatarUrl: data['avatar_url'] as String? ?? '',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: _formatNumber(points),
                        label: 'PONTOS',
                        icon: Icons.workspace_premium_rounded,
                        color: _kBlue,
                        bg: _kBlueSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '$checkins',
                        label: 'CHECK-INS',
                        icon: Icons.qr_code_scanner_rounded,
                        color: _kGreen,
                        bg: _kLimeSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '${streak}d',
                        label: 'SEQU\u00CANCIA',
                        icon: Icons.local_fire_department_rounded,
                        color: _kAmber,
                        bg: _kAmberSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ProfileMenuCard(
                  onEdit: () => setState(() => _isEditing = !_isEditing),
                  onProgress: _openProgress,
                  onGoal: _openGoal,
                  onSettings: _openSettings,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  _EditProfileCard(
                    nomeController: _nomeController,
                    pesoController: _pesoController,
                    alturaController: _alturaController,
                    academiaController: _academiaController,
                  ),
                  const SizedBox(height: 14),
                  _SaveButton(loading: _isSaving, onTap: _saveProfile),
                ],
                const SizedBox(height: 22),
                _SignOutButton(onTap: _signOut),
              ],
            ),
          );
        },
      ),
    );
  }

  String get _displayName {
    final name = _nomeController.text.trim();
    return name.isNotEmpty ? name : 'Usu\u00E1rio';
  }

  Future<void> _openProgress() async {
    await Navigator.pushNamed(context, '/progress');
    if (mounted) setState(() => _profileFuture = _loadProfile());
  }

  Future<void> _openGoal() async {
    if (_goalData == null) {
      final peso = double.tryParse(_pesoController.text);
      final altura = double.tryParse(_alturaController.text);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateGoalPage(
            initialWeight: peso,
            initialHeight: altura,
          ),
        ),
      );
    } else {
      await Navigator.pushNamed(context, '/goals');
    }
    if (mounted) setState(() => _profileFuture = _loadProfile());
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    if (mounted) setState(() => _profileFuture = _loadProfile());
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool editing;
  final VoidCallback onEditToggle;

  const _ProfileHeader({
    required this.editing,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'Perfil',
            style: _pjs(size: 22, weight: FontWeight.w700, color: _kInk, height: 1, letterSpacing: -0.6),
          ),
        ),
        GestureDetector(
          onTap: onEditToggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _shadow(tight: true),
            ),
            child: Icon(editing ? Icons.close_rounded : Icons.edit_rounded, color: _kInk, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String gymName;
  final String avatarUrl;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.gymName,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.characters.first.toUpperCase();
    final hasAvatar = avatarUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      clipBehavior: Clip.antiAlias,
      decoration: _whiteDecoration(26),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: _ActiveBadge(),
              ),
              const SizedBox(height: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kBlue, _kBlue2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: hasAvatar
                        ? Image.network(
                            avatarUrl.trim(),
                            fit: BoxFit.cover,
                            width: 96,
                            height: 96,
                            errorBuilder: (_, _, _) => Text(
                              initial,
                              style: _pjs(size: 38, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                            ),
                          )
                        : Text(
                            initial,
                            style: _pjs(size: 38, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                          ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 22, weight: FontWeight.w800, color: _kInk, height: 1.1, letterSpacing: -0.5),
              ),
              const SizedBox(height: 7),
              Text(
                email,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(size: 13, weight: FontWeight.w500, color: _kMuted),
              ),
              if (gymName.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: _kMuted, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Academia ',
                        style: _pjs(size: 12.5, weight: FontWeight.w600, color: _kMuted),
                      ),
                      Flexible(
                        child: Text(
                          gymName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _pjs(size: 12.5, weight: FontWeight.w800, color: _kInk),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: _kLimeSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _kGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withValues(alpha: 0.70),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'MEMBRO ATIVO',
            style: _pjs(size: 10, weight: FontWeight.w800, color: _kGreen, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: _whiteDecoration(18),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _sg(size: 20, weight: FontWeight.w700, color: _kInk, height: 1, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pjs(size: 10.5, weight: FontWeight.w700, color: _kMuted, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onProgress;
  final VoidCallback onGoal;
  final VoidCallback onSettings;

  const _ProfileMenuCard({
    required this.onEdit,
    required this.onProgress,
    required this.onGoal,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          _MenuRow(
            title: 'Editar perfil',
            icon: Icons.edit_rounded,
            bg: _kBlueSoft,
            color: _kBlue,
            onTap: onEdit,
          ),
          _MenuRow(
            title: 'Meu progresso',
            icon: Icons.show_chart_rounded,
            bg: _kLimeSoft,
            color: _kGreen,
            onTap: onProgress,
          ),
          _MenuRow(
            title: 'Minha meta',
            icon: Icons.flag_rounded,
            bg: _kBlueSoft,
            color: _kBlue,
            onTap: onGoal,
          ),
          _MenuRow(
            title: 'Configura\u00E7\u00F5es',
            icon: Icons.settings_rounded,
            bg: const Color(0xFFF1F3F8),
            color: _kMuted,
            showDivider: false,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg;
  final Color color;
  final bool showDivider;
  final VoidCallback onTap;

  const _MenuRow({
    required this.title,
    required this.icon,
    required this.bg,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: Color(0x0C0E1116))) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: _pjs(size: 14.5, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.2),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSoft, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EditProfileCard extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController pesoController;
  final TextEditingController alturaController;
  final TextEditingController academiaController;

  const _EditProfileCard({
    required this.nomeController,
    required this.pesoController,
    required this.alturaController,
    required this.academiaController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteDecoration(20),
      child: Column(
        children: [
          _ProfileField(
            controller: nomeController,
            label: 'Nome completo',
            icon: Icons.badge_outlined,
            validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigat\u00F3rio' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProfileField(
                  controller: pesoController,
                  label: 'Peso',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileField(
                  controller: alturaController,
                  label: 'Altura',
                  icon: Icons.height_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: academiaController,
            label: 'Academia',
            icon: Icons.storefront_rounded,
            readOnly: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: _pjs(size: 14, weight: FontWeight.w600, color: _kInk),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: readOnly ? _kSoft : _kMuted),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF7F9FC) : Colors.white,
        labelStyle: _pjs(size: 13, weight: FontWeight.w600, color: _kSoft),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBlue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kRed, width: 1.4),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SaveButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: loading ? 0.72 : 1,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kBlue, _kBlue2]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                )
              : Text(
                  'Salvar altera\u00E7\u00F5es',
                  style: _pjs(size: 14, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRed.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: _kRed, size: 16),
            const SizedBox(width: 8),
            Text(
              'Sair da conta',
              style: _pjs(size: 13.5, weight: FontWeight.w700, color: _kRed, letterSpacing: -0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _whiteDecoration(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, color: _kRed, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Erro ao carregar perfil', style: _pjs(size: 16, weight: FontWeight.w800, color: _kInk)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(14)),
                  child: Text('Tentar novamente', style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _whiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: _shadow(),
  );
}

List<BoxShadow> _shadow({bool tight = false}) {
  return [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    if (!tight)
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
  ];
}

String _formatNumber(int value) => NumberFormat.decimalPattern('pt_BR').format(value);

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _sg({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
