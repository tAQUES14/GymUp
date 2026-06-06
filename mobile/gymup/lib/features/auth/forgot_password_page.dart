import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';
import 'package:gymup/features/auth/auth_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthApiService().forgotPassword(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sent = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthSnack(context, authError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _sent ? _buildSuccess(context) : _buildForm(),
        ),
        if (!_sent) ...[
          const SizedBox(height: 18),
          AuthSecondaryButton(
            label: 'Voltar ao login',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('forgot-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          title: 'Recuperar senha',
          subtitle: 'Informe seu email e enviaremos as instrucoes para criar uma nova senha.',
        ),
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
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe seu email.';
                  if (!text.contains('@')) return 'Informe um email valido.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Enviar link de recuperacao',
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
      key: const ValueKey('forgot-success'),
      icon: Icons.mark_email_read_rounded,
      iconColor: authGreen,
      title: 'Email enviado',
      body:
          'Se o email existir em nossa base, voce recebera as instrucoes em breve. Verifique tambem sua caixa de spam.',
      buttonLabel: 'Voltar ao login',
      onButtonTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_) => false,
      ),
    );
  }
}
