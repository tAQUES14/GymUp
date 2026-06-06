import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';
import 'package:gymup/features/auth/auth_ui.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _done = false;
  bool _tokenExpired = false;

  String? _token;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _token = args['token'] as String?;
      _email = args['email'] as String?;
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
      showAuthSnack(
        context,
        'Link invalido. Solicite um novo link de recuperacao.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthApiService().resetPassword(
        token: _token!,
        email: _email!,
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _done = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      final message = authError(error);
      final lower = message.toLowerCase();
      final expired = lower.contains('token') ||
          lower.contains('expirado') ||
          lower.contains('invalido');
      setState(() {
        _tokenExpired = expired;
        _isLoading = false;
      });
      if (!expired) showAuthSnack(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _done
              ? _buildSuccess(context)
              : _tokenExpired
                  ? _buildExpired(context)
                  : _buildForm(),
        ),
        if (!_done && !_tokenExpired) ...[
          const SizedBox(height: 18),
          AuthSecondaryButton(
            label: 'Voltar ao login',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('reset-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          title: 'Criar nova senha',
          subtitle: 'Sua nova senha deve ter pelo menos 6 caracteres.',
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _passwordController,
                label: 'Nova senha',
                hint: 'Digite sua nova senha',
                prefixSvg: authLockSvg,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authSoftMuted,
                    size: 20,
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirmar senha',
                hint: 'Repita a nova senha',
                prefixSvg: authLockSvg,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authSoftMuted,
                    size: 20,
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'As senhas nao coincidem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Redefinir senha',
                onTap: _submit,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return AuthStatusCard(
      key: const ValueKey('reset-success'),
      icon: Icons.check_circle_rounded,
      iconColor: authGreen,
      title: 'Senha redefinida',
      body: 'Sua senha foi atualizada com sucesso. Faca login com a nova senha.',
      buttonLabel: 'Ir para o login',
      onButtonTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_) => false,
      ),
    );
  }

  Widget _buildExpired(BuildContext context) {
    return AuthStatusCard(
      key: const ValueKey('reset-expired'),
      icon: Icons.timer_off_rounded,
      iconColor: Colors.red.shade500,
      title: 'Link expirado',
      body:
          'Este link de recuperacao expirou ou ja foi utilizado. Solicite um novo link para continuar.',
      buttonLabel: 'Solicitar novo link',
      onButtonTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/forgot-password',
        (_) => false,
      ),
    );
  }
}
