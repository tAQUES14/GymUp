import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymup/core/widgets/gym_feedback.dart';

const authBg = Color(0xFFF4F6FA);
const authInk = Color(0xFF000D08);
const authText = Color(0xFF0E1116);
const authMuted = Color(0xFF6D7371);
const authSoftMuted = Color(0xFF9AA3B0);
const authBlue = Color(0xFF2F6FED);
const authBlueDark = Color(0xFF1F4FC4);
const authBlueLight = Color(0xFF4A8CFF);
const authBorder = Color(0x19000D08);
const authGreen = Color(0xFF10B981);
const authRadius = 12.0;
const authButtonRadius = 100.0;

const authGoogleSvg = '''
<svg width="20" height="21" viewBox="0 0 20 21" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M19.7504 10.2456C19.7504 9.51343 19.6845 8.81284 19.562 8.13916H10.0854V11.9988L15.5432 12C15.3218 13.2842 14.6094 14.3789 13.5179 15.1087V17.6128H16.7666C18.6636 15.869 19.7504 13.2912 19.7504 10.2456Z" fill="#4285F4"/>
<path d="M13.519 15.1085C12.6147 15.7144 11.4501 16.0688 10.0877 16.0688C7.45602 16.0688 5.22347 14.3074 4.42394 11.9331H1.07275V14.5156C2.73304 17.7881 6.14545 20.0337 10.0877 20.0337C12.8125 20.0337 15.1016 19.1436 16.7677 17.6115L13.519 15.1085Z" fill="#34A853"/>
<path d="M4.10832 10.0175C4.10832 9.35081 4.22018 8.70637 4.42389 8.10052V5.51807H1.07271C0.386221 6.87128 0 8.39877 0 10.0175C0 11.6362 0.387398 13.1637 1.07271 14.5169L4.42389 11.9344C4.22018 11.3286 4.10832 10.6841 4.10832 10.0175Z" fill="#FABB05"/>
<path d="M10.0877 3.96491C11.5749 3.96491 12.9067 4.47368 13.9582 5.46783L16.8372 2.61052C15.0886 0.992982 12.809 0 10.0877 0C6.14663 0 2.73304 2.24561 1.07275 5.51812L4.42394 8.10058C5.22347 5.72631 7.45602 3.96491 10.0877 3.96491Z" fill="#E94235"/>
</svg>
''';

const authLockSvg = '''
<svg width="13" height="16" viewBox="0 0 13 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M10.5 15.5H2.16667C1.24583 15.5 0.5 14.7542 0.5 13.8333V7.16667C0.5 6.24583 1.24583 5.5 2.16667 5.5H10.5C11.4208 5.5 12.1667 6.24583 12.1667 7.16667V13.8333C12.1667 14.7542 11.4208 15.5 10.5 15.5Z" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M6.33366 12.2418V10.0835" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M6.77544 9.01655C7.01952 9.26063 7.01952 9.65636 6.77544 9.90044C6.53136 10.1445 6.13563 10.1445 5.89155 9.90044C5.64748 9.65636 5.64748 9.26063 5.89155 9.01655C6.13563 8.77248 6.53136 8.77248 6.77544 9.01655" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3 5.5V3.83333V3.83333C3 1.9925 4.4925 0.5 6.33333 0.5V0.5C8.17417 0.5 9.66667 1.9925 9.66667 3.83333V3.83333V5.5" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const authEmailSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M17.5 7.9165L11.3113 10.5644C10.4738 10.9228 9.52618 10.9228 8.68869 10.5644L2.5 7.9165" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="2.5" y="4.1665" width="15" height="12.5" rx="4" stroke="#2F6FED" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const authTitleStyle = TextStyle(
  color: authInk,
  fontSize: 28,
  fontFamily: 'Plus Jakarta Sans',
  fontWeight: FontWeight.w600,
  height: 1.2,
  letterSpacing: -0.4,
);

const authBodyStyle = TextStyle(
  color: authMuted,
  fontSize: 13,
  fontFamily: 'Plus Jakarta Sans',
  fontWeight: FontWeight.w500,
  height: 1.45,
);

void showAuthSnack(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  showGymSnack(
    context,
    message,
    kind: success ? GymFeedbackKind.success : GymFeedbackKind.error,
  );
}

String authError(Object error, [String fallback = 'Algo deu errado.']) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty ? fallback : message;
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.bottomChildren = const [],
    this.footer,
    this.topPadding = 54,
  });

  final List<Widget> children;
  final List<Widget> bottomChildren;
  final Widget? footer;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, topPadding, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - topPadding - 28,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthLogo(),
                          const SizedBox(height: 54),
                          ...children,
                          if (bottomChildren.isNotEmpty) ...[
                            const Spacer(),
                            const SizedBox(height: 40),
                            ...bottomChildren,
                          ],
                          if (footer != null) ...[
                            const SizedBox(height: 22),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [authBlueDark, authBlue, authBlueLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: authBlue.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(
                text: 'Gym',
                style: TextStyle(
                  color: authText,
                  fontSize: 22,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
              TextSpan(
                text: 'Up',
                style: TextStyle(
                  color: authBlue,
                  fontSize: 22,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: authTitleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: authBodyStyle,
          ),
        ],
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.prefixSvg,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? prefixSvg;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: authMuted,
              fontSize: 10,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLength: maxLength,
          style: const TextStyle(
            color: authInk,
            fontSize: 16,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            height: 1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefixSvg == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 18, right: 12),
                    child: SvgPicture.string(
                      prefixSvg!,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
            prefixIconConstraints:
                prefixSvg == null ? null : const BoxConstraints(minWidth: 48),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            errorMaxLines: 2,
            hintStyle: const TextStyle(
              color: Color(0x73000D08),
              fontSize: 15,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(authRadius),
              borderSide: const BorderSide(color: authBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(authRadius),
              borderSide: const BorderSide(color: authBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(authRadius),
              borderSide: const BorderSide(color: authBlue, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(authRadius),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(authRadius),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: loading ? 0.72 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [authBlueDark, authBlue, authBlueLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(authButtonRadius),
            boxShadow: [
              BoxShadow(
                color: authBlue.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(authButtonRadius),
          border: Border.all(color: authBorder),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: authInk,
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.svg,
    required this.onTap,
  });

  final String label;
  final String svg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(authButtonRadius),
          border: Border.all(color: authBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(svg, width: 20, height: 20),
            const SizedBox(width: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: authInk,
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
                height: 0.9,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'Ou'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: authBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xB2000D08),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: -0.28,
            ),
          ),
        ),
        const Expanded(child: Divider(color: authBorder)),
      ],
    );
  }
}

class AuthStatusCard extends StatelessWidget {
  const AuthStatusCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0F0E1116)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: authText,
              fontSize: 19,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center, style: authBodyStyle),
          const SizedBox(height: 22),
          AuthPrimaryButton(label: buttonLabel, onTap: onButtonTap),
        ],
      ),
    );
  }
}
