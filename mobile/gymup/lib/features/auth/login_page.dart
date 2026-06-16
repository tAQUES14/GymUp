import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';
import 'package:gymup/features/auth/google_auth_flow.dart';
import 'package:gymup/features/auth/google_invite_page.dart';
import 'package:gymup/features/auth/auth_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _resendingVerification = false;
  bool _obscurePassword = true;
  String? _unverifiedEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (error) {
      if (!mounted) return;
      if (error is AuthApiException && error.code == 'email_unverified') {
        setState(() => _unverifiedEmail = error.email ?? _emailController.text.trim());
        showAuthSnack(context, error.message);
      } else {
        showAuthSnack(context, authError(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerification() async {
    final email = (_unverifiedEmail ?? _emailController.text).trim();
    if (email.isEmpty) return;

    setState(() => _resendingVerification = true);
    try {
      await AuthApiService().resendVerificationEmail(email: email);
      if (mounted) {
        showAuthSnack(
          context,
          'Enviamos um novo link de verificacao para seu email.',
          success: true,
        );
      }
    } catch (error) {
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _resendingVerification = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final outcome = await GoogleAuthFlow().signIn();
      if (!mounted || outcome.cancelled) return;

      if (outcome.needsInvite) {
        Navigator.pushNamed(
          context,
          '/google-invite',
          arguments: GoogleInviteArgs(
            idToken: outcome.idToken!,
            name: outcome.name ?? 'Conta Google',
            email: outcome.email ?? '',
            picture: outcome.picture,
          ),
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (error) {
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      bottomChildren: [
        AuthPrimaryButton(
          label: 'Fazer Login',
          onTap: _login,
          loading: _isLoading,
        ),
        const SizedBox(height: 16),
        AuthSecondaryButton(
          label: 'Criar Conta',
          onTap: () => Navigator.pushNamed(context, '/register'),
        ),
      ],
      children: [
        const AuthHeader(title: 'Bem vindo de volta'),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'seuemail@email.com',
                prefixSvg: authEmailSvg,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe seu email.';
                  if (!text.contains('@')) return 'Informe um email valido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Senha',
                hint: 'Digite sua senha',
                prefixSvg: authLockSvg,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
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
                  if ((value ?? '').isEmpty) return 'Informe sua senha.';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/forgot-password',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: authBlue,
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              if (_unverifiedEmail != null) ...[
                const SizedBox(height: 8),
                _EmailVerificationCard(
                  email: _unverifiedEmail!,
                  loading: _resendingVerification,
                  onResend: _resendVerification,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        const AuthDivider(),
        const SizedBox(height: 20),
        AuthSocialButton(
          label: 'Continuar com Google',
          svg: authGoogleSvg,
          onTap: _loginWithGoogle,
        ),
      ],
    );
  }
}

class _EmailVerificationCard extends StatelessWidget {
  const _EmailVerificationCard({
    required this.email,
    required this.loading,
    required this.onResend,
  });

  final String email;
  final bool loading;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: authBlue.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirme seu email',
            style: TextStyle(
              color: authText,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enviamos o link para $email. Verifique sua caixa de entrada ou spam.',
            style: const TextStyle(
              color: authMuted,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: loading ? null : onResend,
            style: TextButton.styleFrom(
              foregroundColor: authBlue,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(loading ? 'Reenviando...' : 'Reenviar link'),
          ),
        ],
      ),
    );
  }
}
