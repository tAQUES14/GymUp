import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';
import 'package:gymup/features/auth/google_auth_flow.dart';
import 'package:gymup/features/auth/google_invite_page.dart';
import 'package:gymup/features/auth/auth_ui.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteController = TextEditingController();

  bool _isLoading = false;
  bool _resendingVerification = false;
  bool _obscurePassword = true;
  bool _inviteLookingUp = false;
  String? _invitedGymName;
  String? _inviteError;
  String? _verificationEmail;
  Timer? _inviteDebounce;

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
    final code = value.trim();

    if (code.isEmpty) {
      setState(() {
        _inviteLookingUp = false;
        _invitedGymName = null;
        _inviteError = null;
      });
      return;
    }

    setState(() {
      _inviteLookingUp = true;
      _invitedGymName = null;
      _inviteError = null;
    });

    _inviteDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _lookupInvite(code),
    );
  }

  Future<void> _lookupInvite(String code) async {
    try {
      final gym = await AuthApiService().getGymByInvite(code);
      if (!mounted) return;
      setState(() {
        _invitedGymName = gym['name'] as String?;
        _inviteError = null;
        _inviteLookingUp = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invitedGymName = null;
        _inviteError = 'Codigo invalido. Verifique e tente novamente.';
        _inviteLookingUp = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final invite = _inviteController.text.trim();
      await AuthApiService().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        inviteCode: invite.isEmpty ? null : invite,
      );
      if (mounted) {
        setState(() => _verificationEmail = _emailController.text.trim());
      }
    } catch (error) {
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerification() async {
    final email = _verificationEmail;
    if (email == null || email.isEmpty) return;

    setState(() => _resendingVerification = true);
    try {
      await AuthApiService().resendVerificationEmail(email: email);
      if (mounted) {
        showAuthSnack(
          context,
          'Enviamos um novo link de verificacao.',
          success: true,
        );
      }
    } catch (error) {
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _resendingVerification = false);
    }
  }

  Future<void> _registerWithGoogle() async {
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
    if (_verificationEmail != null) {
      return AuthScaffold(
        children: [
          AuthStatusCard(
            icon: Icons.mark_email_read_rounded,
            iconColor: authGreen,
            title: 'Confirme seu email',
            body:
                'Enviamos um link para $_verificationEmail. Abra o email para liberar seu acesso ao GymUp.',
            buttonLabel: 'Ir para o login',
            onButtonTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            ),
          ),
          const SizedBox(height: 16),
          AuthSecondaryButton(
            label: _resendingVerification ? 'Reenviando...' : 'Reenviar email',
            onTap: _resendingVerification ? null : _resendVerification,
          ),
        ],
      );
    }

    return AuthScaffold(
      topPadding: 42,
      children: [
        const AuthHeader(
          title: 'Criar conta',
          subtitle: 'Entre na sua academia e acompanhe treinos, desafios e recompensas.',
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Nome',
                hint: 'Seu nome completo',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Informe seu nome.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                hint: 'Minimo de 6 caracteres',
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
              const SizedBox(height: 18),
              const AuthDivider(label: 'Codigo de convite'),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _inviteController,
                label: 'Academia',
                hint: 'Opcional',
                maxLength: 8,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: _onInviteChanged,
                suffixIcon: _inviteLookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: authSoftMuted,
                          ),
                        ),
                      )
                    : null,
              ),
              if (_invitedGymName != null || _inviteError != null) ...[
                const SizedBox(height: 10),
                _InviteFeedback(
                  successText: _invitedGymName == null
                      ? null
                      : 'Voce esta se cadastrando na $_invitedGymName',
                  errorText: _inviteError,
                ),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Criar Conta',
                onTap: _register,
                loading: _isLoading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const AuthDivider(),
        const SizedBox(height: 20),
        AuthSocialButton(
          label: 'Continuar com Google',
          svg: authGoogleSvg,
          onTap: _registerWithGoogle,
        ),
        const SizedBox(height: 18),
        AuthSecondaryButton(
          label: 'Fazer Login',
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (_) => false,
          ),
        ),
      ],
    );
  }
}

class _InviteFeedback extends StatelessWidget {
  const _InviteFeedback({this.successText, this.errorText});

  final String? successText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final success = successText != null;
    final color = success ? authGreen : Colors.red.shade600;
    final bg = success ? const Color(0xFFEFFBF4) : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              successText ?? errorText ?? '',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
