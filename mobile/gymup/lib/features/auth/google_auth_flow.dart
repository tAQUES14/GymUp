import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api_service.dart';
import 'auth_google_config.dart';

class GoogleAuthOutcome {
  final bool cancelled;
  final bool needsInvite;
  final String? idToken;
  final String? name;
  final String? email;
  final String? picture;

  const GoogleAuthOutcome._({
    required this.cancelled,
    required this.needsInvite,
    this.idToken,
    this.name,
    this.email,
    this.picture,
  });

  const GoogleAuthOutcome.cancelled()
      : this._(cancelled: true, needsInvite: false);

  const GoogleAuthOutcome.signedIn()
      : this._(cancelled: false, needsInvite: false);

  const GoogleAuthOutcome.needsInvite({
    required this.idToken,
    required this.name,
    required this.email,
    this.picture,
  }) : cancelled = false,
       needsInvite = true;
}

class GoogleAuthFlow {
  final GoogleSignIn _googleSignIn = _createGoogleSignIn();
  final AuthApiService _api = AuthApiService();

  static GoogleSignIn _createGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: AuthGoogleConfig.webClientId,
      );
    }

    return GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: AuthGoogleConfig.serverClientId,
    );
  }

  Future<GoogleAuthOutcome> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return const GoogleAuthOutcome.cancelled();

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Nao foi possivel validar sua conta Google.');
    }

    final data = await _api.googleAuth(idToken: idToken);
    if (data['needs_invite'] == true) {
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      return GoogleAuthOutcome.needsInvite(
        idToken: idToken,
        name: (profile['name'] ?? account.displayName ?? 'Conta Google')
            .toString(),
        email: (profile['email'] ?? account.email).toString(),
        picture: (profile['picture'] ?? account.photoUrl)?.toString(),
      );
    }

    return const GoogleAuthOutcome.signedIn();
  }
}
