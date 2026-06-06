import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymup/features/auth/auth_api_service.dart';
import 'package:gymup/features/auth/auth_ui.dart';

class GoogleInviteArgs {
  final String idToken;
  final String name;
  final String email;
  final String? picture;

  const GoogleInviteArgs({
    required this.idToken,
    required this.name,
    required this.email,
    this.picture,
  });
}

class GoogleInvitePage extends StatefulWidget {
  const GoogleInvitePage({super.key});

  @override
  State<GoogleInvitePage> createState() => _GoogleInvitePageState();
}

class _GoogleInvitePageState extends State<GoogleInvitePage> {
  final _inviteController = TextEditingController();
  final _api = AuthApiService();

  GoogleInviteArgs? _args;
  Timer? _debounce;
  bool _lookingUp = false;
  bool _isLoading = false;
  String? _gymName;
  String? _inviteError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)?.settings.arguments as GoogleInviteArgs?;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inviteController.dispose();
    super.dispose();
  }

  void _onInviteChanged(String value) {
    _debounce?.cancel();
    final code = value.trim();

    if (code.isEmpty) {
      setState(() {
        _lookingUp = false;
        _gymName = null;
        _inviteError = null;
      });
      return;
    }

    setState(() {
      _lookingUp = true;
      _gymName = null;
      _inviteError = null;
    });

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _lookupInvite(code),
    );
  }

  Future<void> _lookupInvite(String code) async {
    try {
      final gym = await _api.getGymByInvite(code);
      if (!mounted) return;
      setState(() {
        _gymName = gym['name'] as String?;
        _inviteError = null;
        _lookingUp = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gymName = null;
        _inviteError = 'Codigo invalido. Verifique e tente novamente.';
        _lookingUp = false;
      });
    }
  }

  Future<void> _finish() async {
    final args = _args;
    final invite = _inviteController.text.trim();
    if (args == null) {
      showAuthSnack(context, 'Sessao Google expirada. Tente novamente.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }
    if (invite.isEmpty) {
      setState(() => _inviteError = 'Informe o codigo da sua academia.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.googleAuth(idToken: args.idToken, inviteCode: invite);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (error) {
      if (mounted) showAuthSnack(context, authError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    return AuthScaffold(
      topPadding: 42,
      bottomChildren: [
        AuthPrimaryButton(
          label: 'Entrar na academia',
          onTap: _finish,
          loading: _isLoading,
        ),
        const SizedBox(height: 16),
        AuthSecondaryButton(
          label: 'Voltar ao login',
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (_) => false,
          ),
        ),
      ],
      children: [
        const AuthHeader(
          title: 'Convite da academia',
          subtitle:
              'Sua conta Google foi validada. Agora informe o codigo enviado pela academia para liberar seu acesso.',
        ),
        const SizedBox(height: 26),
        _GoogleAccountCard(args: args),
        const SizedBox(height: 26),
        AuthTextField(
          controller: _inviteController,
          label: 'Academia',
          hint: 'Codigo de convite',
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: _onInviteChanged,
          suffixIcon: _lookingUp
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
        if (_gymName != null || _inviteError != null) ...[
          const SizedBox(height: 10),
          _InviteFeedback(
            successText: _gymName == null ? null : 'Voce esta entrando na $_gymName',
            errorText: _inviteError,
          ),
        ],
      ],
    );
  }
}

class _GoogleAccountCard extends StatelessWidget {
  const _GoogleAccountCard({required this.args});

  final GoogleInviteArgs? args;

  @override
  Widget build(BuildContext context) {
    final name = args?.name.trim().isNotEmpty == true ? args!.name : 'Conta Google';
    final email = args?.email ?? '';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: authBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF1FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: authBlue,
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authText,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authMuted,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
