import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);
const _kGreen    = Color(0xFF10B981);

class ResetPasswordPage extends StatefulWidget {
  /// Recebe {token, email} via Navigator arguments ou deep link.
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey               = GlobalKey<FormState>();
  final _passwordController    = TextEditingController();
  final _confirmController     = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _done            = false;
  bool _tokenExpired    = false;

  String? _token;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      _token = args?['token'];
      _email = args?['email'];
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null || _email == null) {
      _showError('Link inválido. Solicite um novo link de recuperação.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthApiService().resetPassword(
        token:    _token!,
        email:    _email!,
        password: _passwordController.text.trim(),
      );
      if (mounted) setState(() { _isLoading = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final expired = msg.toLowerCase().contains('token') ||
          msg.toLowerCase().contains('expirado') ||
          msg.toLowerCase().contains('inválido');
      setState(() { _isLoading = false; _tokenExpired = expired; });
      if (!expired) _showError(msg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── InputDecoration helper ─────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ── CTA button ─────────────────────────────────────────────────────────────

  Widget _ctaButton({
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                color: _kBlue.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
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
                    'Redefinir senha',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Card com AnimatedSwitcher ─────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _done
                        ? _buildSuccess()
                        : _tokenExpired
                            ? _buildExpired()
                            : _buildForm(),
                  ),

                  const SizedBox(height: 28),

                  // ── Link para login ───────────────────────────────────
                  if (!_done && !_tokenExpired)
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(text: 'Lembrou a senha? '),
                            TextSpan(
                              text: 'Voltar ao login',
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

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Container(
      key: const ValueKey('form'),
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
              'Criar nova senha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua nova senha deve ter pelo menos 6 caracteres.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),

            // Nova senha
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B)),
              decoration: _inputDecoration(
                label: 'Nova senha',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Confirmar senha
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B)),
              decoration: _inputDecoration(
                label: 'Confirmar nova senha',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            _ctaButton(
              label: 'Redefinir senha',
              onTap: _isLoading ? null : _submit,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // ── Success ───────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _kGreen, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Senha redefinida!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sua senha foi atualizada com sucesso.\nFaça login com sua nova senha.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF64748B), height: 1.6),
          ),
          const SizedBox(height: 28),
          _ctaButton(
            label: 'Ir para o login',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (_) => false),
          ),
        ],
      ),
    );
  }

  // ── Token expirado ────────────────────────────────────────────────────────

  Widget _buildExpired() {
    return Container(
      key: const ValueKey('expired'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_off_rounded,
                color: Colors.red.shade400, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Link expirado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Este link de recuperação expirou ou já foi utilizado. Solicite um novo link.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF64748B), height: 1.6),
          ),
          const SizedBox(height: 28),
          _ctaButton(
            label: 'Solicitar novo link',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/forgot-password', (_) => false),
          ),
        ],
      ),
    );
  }
}
