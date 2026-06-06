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
  bool _obscurePassword = true;

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
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
