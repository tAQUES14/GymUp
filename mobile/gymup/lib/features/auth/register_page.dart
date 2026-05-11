import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteController   = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  // Invite code lookup state
  bool    _inviteLookingUp = false;
  String? _invitedGymName;
  String? _inviteError;
  Timer?  _inviteDebounce;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    _inviteDebounce?.cancel();
    super.dispose();
  }

  void _onInviteChanged(String value) {
    _inviteDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _invitedGymName  = null;
        _inviteError     = null;
        _inviteLookingUp = false;
      });
      return;
    }

    setState(() {
      _invitedGymName  = null;
      _inviteError     = null;
      _inviteLookingUp = true;
    });

    _inviteDebounce = Timer(const Duration(milliseconds: 500), () => _lookupInvite(trimmed));
  }

  Future<void> _lookupInvite(String code) async {
    try {
      final gym = await AuthApiService().getGymByInvite(code);
      if (mounted) {
        setState(() {
          _invitedGymName  = gym['name'] as String;
          _inviteError     = null;
          _inviteLookingUp = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invitedGymName  = null;
          _inviteError     = 'Código inválido. Verifique e tente novamente.';
          _inviteLookingUp = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final invite = _inviteController.text.trim();
      await AuthApiService().register(
        name:       _nameController.text.trim(),
        email:      _emailController.text.trim(),
        password:   _passwordController.text.trim(),
        inviteCode: invite.isNotEmpty ? invite : null,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Input decoration ──────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle:
          const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBlue, _kBlueDark, Color(0xFF1E3A8A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Branding ─────────────────────────────────────────
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GymUp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comece sua jornada fitness',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Form card ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Criar sua conta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Nome ─────────────────────────────────────
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization:
                                TextCapitalization.words,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B)),
                            decoration: _inputDecoration(
                              label: 'Nome completo',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Por favor, insira seu nome';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // ── E-mail ───────────────────────────────────
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B)),
                            decoration: _inputDecoration(
                              label: 'E-mail',
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Por favor, insira seu e-mail';
                              }
                              if (!v.contains('@')) {
                                return 'Informe um e-mail válido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // ── Senha ────────────────────────────────────
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B)),
                            decoration: _inputDecoration(
                              label: 'Senha',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Divisor ──────────────────────────────────
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Código de convite (opcional)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Código de convite ─────────────────────────
                          TextFormField(
                            controller: _inviteController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              label: 'Código da academia',
                              prefixIcon: Icons.tag_rounded,
                              suffixIcon: _inviteLookingUp
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    )
                                  : null,
                            ).copyWith(counterText: ''),
                            onChanged: _onInviteChanged,
                          ),

                          // ── Feedback do lookup ────────────────────────
                          if (_invitedGymName != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Você está se cadastrando na $_invitedGymName',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF15803D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_inviteError != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 15,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _inviteError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── CTA ──────────────────────────────────────
                          GestureDetector(
                            onTap: _isLoading ? null : _register,
                            child: AnimatedOpacity(
                              duration:
                                  const Duration(milliseconds: 200),
                              opacity: _isLoading ? 0.7 : 1.0,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kBlue, _kBlueDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kBlue.withValues(
                                          alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child:
                                              CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Criar conta',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Login link ────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                        children: const [
                          TextSpan(text: 'Já tem uma conta? '),
                          TextSpan(
                            text: 'Entrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
