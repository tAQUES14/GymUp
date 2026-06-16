import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymup/core/widgets/gymup_loading.dart';
import 'package:gymup/features/auth/auth_service.dart';
import 'package:gymup/features/auth/login_page.dart';
import 'package:gymup/features/onboarding/onboarding_page.dart';
import 'package:gymup/features/shell/app_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = context.read<AuthService>();
    final token = await authService.getToken();
    final hasSeenOnboarding = await OnboardingPage.hasSeen();

    setState(() {
      _isLoggedIn = token != null;
      _hasSeenOnboarding = hasSeenOnboarding;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: GymUpLoading()),
      );
    }

    if (_isLoggedIn) return const AppShell();
    if (!_hasSeenOnboarding) return const OnboardingPage();
    return const LoginPage();
  }
}
